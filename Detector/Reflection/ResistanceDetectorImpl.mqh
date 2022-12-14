//+------------------------------------------------------------------+
//|                                       ResistanceDetectorImpl.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "ResistanceDetector.mqh"

class ResistanceDetectorImpl : public IResistanceDetector {
private:
    const int numSMA_;
    int smaAverages_[];
    int smaHandles_[];
    
    struct SMABuffer {
        double values_[];
    };
    
    SMABuffer smaBuffers_[];
public:
    ResistanceDetectorImpl(const int &smaAverages[]);
    ~ResistanceDetectorImpl();
    
    bool init();
    void deinit();
    
    int detect(const double& signals[], int start, int limit,
             const datetime &time[],
             const double &open[],
             const double &high[],
             const double &low[],
             const double &close[],
             DetectResult& result);
    
private:
    bool loadSMA(int start, int limit, int smaIdx);
    bool getSMAValue(int index, int limit, int smaIdx, double& sma) const;
    bool isTarget(double signal, double open, double high, double low, double close, double sma);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ResistanceDetectorImpl::ResistanceDetectorImpl(const int &smaAverages[])
        : numSMA_(MathMin((int)NumResistances, ArraySize(smaAverages))) {
    ArrayResize(smaAverages_, numSMA_);
    for (int i = 0; i < numSMA_; i++) {
        smaAverages_[i] = smaAverages[i];
    }
    ArrayResize(smaHandles_, numSMA_);
    ArrayFill(smaHandles_, 0, numSMA_, INVALID_HANDLE);
    ArrayResize(smaBuffers_, numSMA_);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ResistanceDetectorImpl::~ResistanceDetectorImpl() {
    deinit();
    ArrayFree(smaAverages_);
    ArrayFree(smaHandles_);
    int numBuffes = ArraySize(smaBuffers_);
    for (int i = 0; i < numBuffes; i++) {
        ArrayFree(smaBuffers_[i].values_);
    }
    ArrayFree(smaBuffers_);
}
//+------------------------------------------------------------------+

bool ResistanceDetectorImpl::init() {
    if (numSMA_ <= 0) {
        return false;
    }
    
    for (int i = 0; i < numSMA_; i++) {
        smaHandles_[i] = iMA(Symbol(), PERIOD_CURRENT, smaAverages_[i], 0, MODE_SMA, PRICE_CLOSE);
        if (smaHandles_[i] == INVALID_HANDLE) {
            deinit();
            return false;
        }
    }
    return true;
}

void ResistanceDetectorImpl::deinit() {
    for (int i = 0; i < numSMA_; i++) {
        if (smaHandles_[i] != INVALID_HANDLE) {
            IndicatorRelease(smaHandles_[i]);
            smaHandles_[i] = INVALID_HANDLE;
        }
    }
}

int ResistanceDetectorImpl::detect(const double& signals[],
         int start, int limit,
         const datetime &time[],
         const double &open[],
         const double &high[],
         const double &low[],
         const double &close[],
         DetectResult& result) {

    // メモ確保
    if (ArraySize(result.results_) != limit) {
        ArrayResize(result.results_, limit);
    }
    
    // SMA初期化
    for (int smaIdx = 0; smaIdx < numSMA_; smaIdx++) {
        if (!loadSMA(start, limit, smaIdx)) {
            return 0;
        }
    }

    // 検出した個数
    int numFounds = 0;
    
    // チャートの対象区間を走査
    for (int i = start; i < limit; i++) {
        // 初期化
        for (int r = 0; r < NumRanking; r++) {
            result.results_[i].ranking[r].type_ = None;
            result.results_[i].ranking[r].price_ = 0.0;
        }
    
        // シグナルの箇所以外は対象外
        if (signals[i] == 0.0) continue; 
    
        for (int smaIdx = 0; smaIdx < numSMA_; smaIdx++) {
            double sma;
            if (getSMAValue(i, limit, smaIdx, sma) && isTarget(signals[i], open[i], high[i], low[i], close[i], sma)) {
                ResistanceInfo r;
                r.type_ = (Resistance)smaIdx;
                r.price_ = sma;
                
                if (0 < signals[i]) {
                    // 高値の順に抵抗帯を探す
                    result.results_[i].pushOrderDsc(r);
                    numFounds++;
                } else {
                    // 安値の順に抵抗帯を探す
                    result.results_[i].pushOrderAsc(r);
                    numFounds++;
                }
            }
        }
    }
    
    // 処理した個数を返却
    return numFounds;
}

bool ResistanceDetectorImpl::loadSMA(int start, int limit, int smaIdx) {
    if (smaHandles_[smaIdx] == INVALID_HANDLE)
        return false;
    if (ArraySize(smaBuffers_[smaIdx].values_) != limit) {
        ArrayResize(smaBuffers_[smaIdx].values_, limit);
    }
    int handle = smaHandles_[smaIdx];
    CopyBuffer(handle, 0, 0, limit, smaBuffers_[smaIdx].values_);
    return true;
}

bool ResistanceDetectorImpl::getSMAValue(int index, int limit, int smaIdx, double &sma) const {
    if (smaHandles_[smaIdx] == INVALID_HANDLE)
        return false;
    if (ArraySize(smaBuffers_[smaIdx].values_) != limit) {
        return false;
    }
    if (index < smaAverages_[smaIdx] || limit <= index) {
        return false;
    }
    sma = smaBuffers_[smaIdx].values_[index]; // 最後尾(limit-1)が最新
    return true;
}

bool ResistanceDetectorImpl::isTarget(double signal, double open, double high, double low, double close, double sma) {
    if (sma < low || high < sma) {
        return false;
    }
    
    double bodyHigh = MathMax(open, close);
    double bodyLow = MathMin(open, close);    
    double bodyLen = bodyHigh - bodyLow;
    
    if (signal < 0 && (bodyLow + (bodyLen * (2.0/3.0))) <= sma && sma <= high) {
        return false;
    }
    
    if (0 < signal && low <= sma && sma <= (bodyHigh - (bodyLen * (2.0/3.0)))) {
        return false;
    }
    
    return true;
}
