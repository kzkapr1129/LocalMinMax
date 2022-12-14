//+------------------------------------------------------------------+
//|                                        SMAReflectionDetector.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../LocalFeature/LocalFeatureMatcher.mqh"
#include "ReflectionDetector.mqh"

/**
 * SMAの反発を検出する検出器
 */
class SMAReflectionDetector : public IReflectionDetector {
private:
    struct DoubleArray {
        double values_[];
    };

    const int numSMA_;
    const double rangeFactor_;
    const double rangeCorrection_;
    const double badRangeFactor_;
    
    int smaAverages_[];
    int smaHandles_[];

public:
    SMAReflectionDetector(const int &smaAverages[],
        double rangeFactor, double rangeCorrection,
        double badRangeFactor);
    ~SMAReflectionDetector();
    
    // 初期化に成功したか
    bool isInitialized() const;
    
    bool initDetection(int windowSize); 
    bool deinitDetection();
    
    bool detect(int start,
                int limit,
                const Candle &candles[],
                const LocalFeature& localFeatures[],
                LocalFeatureFactors &result[]) const;
            
private:
    bool loadSMA(DoubleArray &smaBuffers[], int limit) const;
    void freeSMA(DoubleArray &smaBuffers[]) const;
    bool isCandleAffected(const DoubleArray& smaBuffer, int index, const LocalFeature &feature,
            const Candle &c) const;
    bool isBadCandle(const DoubleArray& smaBuffer, int index, const LocalFeature &feature,
            const Candle & c) const;
    bool isRangeAffected(const DoubleArray& smaBuffer, const LocalFeature& feature,
            const Candle &candles[]) const;
    
    double distanceToSMA(const DoubleArray& smaBuffer, int index, const LocalFeature& feature,
            const Candle &c) const;
    double distanceToSMAWithRange(const DoubleArray& smaBuffer, const LocalFeature& feature,
            const Candle &candles[]) const;
};

SMAReflectionDetector::SMAReflectionDetector(
        const int &smaAverages[], double rangeFactor, double rangeCorrection, double badRangeFactor)
        : numSMA_(ArraySize(smaAverages)),
          rangeFactor_(rangeFactor),
          rangeCorrection_(rangeCorrection),
          badRangeFactor_(badRangeFactor) {

    if (numSMA_ <= 0) return;
    
    ArrayResize(smaAverages_, numSMA_);
    for (int i = 0; i < numSMA_; i++) {
        smaAverages_[i] = smaAverages[i];
    }

    ArrayResize(smaHandles_, numSMA_);
    for (int i = 0; i < numSMA_; i++) {
        smaHandles_[i] = iMA(Symbol(), PERIOD_CURRENT, smaAverages_[i], 0, MODE_SMA, PRICE_CLOSE);
    }
}

SMAReflectionDetector::~SMAReflectionDetector() {
    for (int i = 0; i < ArraySize(smaHandles_); i++) {
        int handle = smaHandles_[i];
        IndicatorRelease(handle);
    }
    ArrayFree(smaHandles_);
    ArrayFree(smaAverages_);
}

bool SMAReflectionDetector::isInitialized() const {
    // SMAの未指定チェック
    if (numSMA_ <= 0) {
        return false;
    }
    
    // SMAの平均値の初期化に失敗しているかチェック
    if (ArraySize(smaAverages_) != numSMA_) {
        return false;
    }
    for (int i = 0; i < numSMA_; i++) {
        if (smaAverages_[i] <= 0) {
            return false;
        }
    }
    
    // SMAハンドルの初期化に失敗しているかチェック
    if (ArraySize(smaHandles_) != numSMA_) {
        return false;
    }
    for (int i = 0; i < numSMA_; i++) {
        if (smaHandles_[i] == INVALID_HANDLE) {
            return false;
        }
    }
    
    return true;
}

bool SMAReflectionDetector::detect(int start,
            int limit,
            const Candle &candles[],
            const LocalFeature& localFeatures[],
            LocalFeatureFactors& results[]) const {
            
    DoubleArray smaBuffers[];
    if (!loadSMA(smaBuffers, limit)) {
        return false;
    }

    int numFeatures = ArraySize(localFeatures);
    for (int i = 0; i < numFeatures; i++) {
        const LocalFeature feature = localFeatures[i];        
        for (int smaIdx = 0; smaIdx < numSMA_; smaIdx++) {
            if (isRangeAffected(smaBuffers[smaIdx], feature, candles)) {
                LocalFeatureFactor factor;
                factor.type_ = RESISTANCE_TYPE_SMA;
                factor.subType_ = smaIdx;
                factor.factorStart_ = feature.featureStart_;
                factor.factorEnd_ = feature.featureEnd_;
                factor.distanceToResistance_ = distanceToSMAWithRange(smaBuffers[smaIdx], feature, candles);
                
                if (feature.type_ == LOCAL_FEATURE_MAX) {
                    results[i].addSort(factor, LocalFeatureFactors::SORT_DSC);
                } else if (feature.type_ == LOCAL_FEATURE_MIN) {
                    results[i].addSort(factor, LocalFeatureFactors::SORT_ASC);
                }
            }
        }
    }
    
    freeSMA(smaBuffers);
            
    return true;
}

bool SMAReflectionDetector::loadSMA(DoubleArray &smaBuffers[], int limit) const {
    if (ArrayResize(smaBuffers, numSMA_) < 0)
        return false;
    for (int smaIdx = 0; smaIdx < numSMA_; smaIdx++) {
        if (ArrayResize(smaBuffers[smaIdx].values_, limit) < 0)
            return false;
        
        int handle = smaHandles_[smaIdx];
        CopyBuffer(handle, 0, 0, limit, smaBuffers[smaIdx].values_);
        
        // インデックス0番目が最新になるように並び替えする
        if (!ArrayReverse(smaBuffers[smaIdx].values_)) {
            return false;
        }
    }
    return true;
}

void SMAReflectionDetector::freeSMA(DoubleArray &smaBuffers[]) const {
    int n = ArraySize(smaBuffers);
    for (int i = 0; i < n; i++) {
        ArrayFree(smaBuffers[i].values_);
    }
    ArrayFree(smaBuffers);
}


bool SMAReflectionDetector::isCandleAffected(const DoubleArray& smaBuffer, int index, const LocalFeature &feature,
        const Candle &c) const {
        
    double smaValue = smaBuffer.values_[index];
    // SMAが注目ローソク足に影響を与えているかチェック
    if (smaValue < (c.low_ - rangeCorrection_) || (c.high_ + rangeCorrection_) < smaValue) {
        // SMAがローソク足に重なっていない場合
        return false;
    }
    
    double bodyMin = MathMin(c.open_, c.close_);
    double bodyMax = MathMax(c.open_, c.close_);
    double bodyLen = bodyMax - bodyMin;
        
    switch (feature.type_) {
    case LOCAL_FEATURE_MAX: {
            double bodyThreashold = bodyMax - (bodyLen * rangeFactor_);
            if (bodyThreashold <= smaValue && smaValue <= (c.high_ + rangeCorrection_)) {
                // ローソク足の実体上辺から最高値の間にSMAが重なっている場合
                return true;
            }
        }
        break;

    case LOCAL_FEATURE_MIN: {
            double bodyThreashold = bodyMin + (bodyLen * rangeFactor_);
            if ((c.low_ - rangeCorrection_) <= smaValue && smaValue <= bodyThreashold) {
                // ローソク足の実体下辺から最安値の間にSMAが重なっている場合
                return true;
            }
        }
        break;

    default:
        return false;    
    }
    
    return false;
}

bool SMAReflectionDetector::isBadCandle(const DoubleArray& smaBuffer, int index, const LocalFeature &feature,
            const Candle &c) const {
            
    double smaValue = smaBuffer.values_[index];
    
    double bodyMin = MathMin(c.open_, c.close_);
    double bodyMax = MathMax(c.open_, c.close_);    
    double bodyLen = bodyMax - bodyMin;    
    
    switch (feature.type_) {
    case LOCAL_FEATURE_MAX: {     
            if (smaValue < (bodyMin + (bodyLen * badRangeFactor_))) {
                // ローソク足の実体の大半が反射の反対側に抜けている
                return true;
            }
        }
        break;
        
    case LOCAL_FEATURE_MIN: {
            if ((bodyMax - (bodyLen * badRangeFactor_)) < smaValue) {
                // ローソク足の実体の大半が反射の反対側に抜けている
                return true;
            }
        }
        break;
    }
    
    return false;
}

bool SMAReflectionDetector::isRangeAffected(const DoubleArray& smaBuffer, const LocalFeature& feature,
            const Candle &candles[]) const {

    bool foundAffect = false;
    for (int i = feature.featureStart_; i <= feature.featureEnd_; i++) {
        Candle c = candles[i];
        if (isCandleAffected(smaBuffer, i, feature, c)) {
            foundAffect = true;
            continue;
        }
    
        if (isBadCandle(smaBuffer, i, feature, c)) {
            return false;
        }
    }
    
    return foundAffect;
}

double SMAReflectionDetector::distanceToSMA(const DoubleArray& smaBuffer, int index, const LocalFeature& feature, const Candle &c) const {

    double smaValue = smaBuffer.values_[index];

    switch (feature.type_) {
    case LOCAL_FEATURE_MAX: {
            double bodyMax = MathMax(c.open_, c.close_);
            double bodyToSMA = MathAbs(smaValue - bodyMax);
            double highToSMA = MathAbs(smaValue - c.high_);
            return MathMin(bodyToSMA, highToSMA);
        }
        break;
        
    case LOCAL_FEATURE_MIN: {
            double bodyMin = MathMin(c.open_, c.close_);
            double bodyToSMA = MathAbs(smaValue - bodyMin);
            double lowToSMA = MathAbs(smaValue - c.low_);
            return MathMin(bodyToSMA, lowToSMA);
        }
        break;
    }

    return DBL_MAX;
}

double SMAReflectionDetector::distanceToSMAWithRange(const DoubleArray& smaBuffer, const LocalFeature& feature,
            const Candle &candles[]) const {
     
    double sum = 0;       
    for (int i = feature.featureStart_; i <= feature.featureEnd_; i++) {
        sum += smaBuffer.values_[i];
    }
    return sum / (double)(feature.featureEnd_ - feature.featureStart_ + 1);
}