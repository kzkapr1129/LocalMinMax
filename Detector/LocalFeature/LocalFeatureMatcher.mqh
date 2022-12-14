//+------------------------------------------------------------------+
//|                                                 ChartPattern.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Common.mqh"

/**
 * 局所的特徴種別
 */
enum LocalFeatureType {
    /*
     * 局所的特徴なし
     */
    LOCAL_FEATURE_NONE = 0,
    
    /**
     * 局所的な最高値
     */
    LOCAL_FEATURE_MAX = 1,
    
    /**
     * 局所的な最安値
     */
    LOCAL_FEATURE_MIN = -1
};

/**
 * 局所特徴に関する情報を格納する
 */
struct LocalFeature {
    /**
     * 局所的特徴種別
     */
    LocalFeatureType type_;
    /**
     *　局所的特徴の開始点
     */
    int featureStart_;
    /**
     * 局所的特徴の終了点
     */
    int featureEnd_;
    
    LocalFeature() : type_(LOCAL_FEATURE_NONE), featureStart_(0), featureEnd_(0) {}
};

/**
 * 局所的特徴の比較を行うインタフェース
 */
interface ILocalFeatureMatcher {
public:
    bool match(
                int start,
                int index,
                const Candle &candles[],
                LocalFeature& result) const;
             
};
