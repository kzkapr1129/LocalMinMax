//+------------------------------------------------------------------+
//|                                           ReflectionDetector.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../LocalFeature\LocalFeatureMatcher.mqh"

/**
 * 抵抗帯種別
 */
enum ResistanceType {
    RESISTANCE_TYPE_NONE,
    RESISTANCE_TYPE_SMA,
    NUM_RESISTANCE_TYPE
};

/**
 * 局所特徴の発生要因
 */
struct LocalFeatureFactor {
    /** 
     * 抵抗帯種別
     */
    ResistanceType type_;
    
    /**
     * 抵抗帯のサブ種別
     */
    int subType_;
    
    /**
     * 局所特徴の発生要因となった開始箇所
     */
    int factorStart_;
    
    /**
     * 局所特徴の発生要因となった終了箇所
     */
    int factorEnd_;
    
    /**
     * ローソク足の高値または安値から抵抗帯までの距離
     */
    double distanceToResistance_;
};

/**
 * 
 */
struct LocalFeatureFactors {
    LocalFeatureFactor values_[];

    enum SortType {
        SORT_ASC,
        SORT_DSC
    };
    
    void addSort(const LocalFeatureFactor& factor, SortType sortType) {
        // 挿入位置を探す
        int n = ArraySize(values_);
        int insertPos = n;
        for (int i = 0; i < n; i++) {
            bool found = sortType == SORT_ASC ? factor.distanceToResistance_ < values_[i].distanceToResistance_:
                factor.distanceToResistance_ > values_[i].distanceToResistance_;
            if (found) {
                insertPos = i;
                break;
            }
        }

        // 挿入用メモリ確保
        int newSize = n + 1;
        ArrayResize(values_, newSize);
        
        // 挿入先から最後尾までずらす
        for (int i = newSize - 1; insertPos < i; i--) {
            values_[i] = values_[i-1];
        }
        
        // 要素の挿入
        values_[insertPos] = factor;
    }
};

/**
 * 局所特徴の発生要因を検出するためインタフェース
 */
interface IReflectionDetector {
public:   
    bool detect(int start,
                int limit,
                const Candle &candles[],
                const LocalFeature& localFeatures[],
                LocalFeatureFactors &result[]) const;
};