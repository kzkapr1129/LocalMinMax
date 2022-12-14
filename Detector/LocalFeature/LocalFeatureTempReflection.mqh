//+------------------------------------------------------------------+
//|                              ChartPatternTemporaryReflection.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Common.mqh"
#include "LocalFeatureMatcher.mqh"

/**
 * 局所的特徴の検出器: 長い実体をもつローソク足に対しての一時的な反発を検出する
 */
class LocalFeatureTempReflection : public ILocalFeatureMatcher {
private:
    enum TargetType {
        UP_CANDLE,
        DOWN_CANDLE
    };

    int timeout_;
    
public:
    LocalFeatureTempReflection(int timeout);
    ~LocalFeatureTempReflection();
     
    bool match(
         int start,
         int index,
         const Candle &candles[],
         LocalFeature& result) const;
         
private:
    bool isTarget(const Candle& c, const Candle& pre, const Candle& pre2, const Candle& pre3) const;
    int findTargetCandle(int start, int end,
         const Candle &candles[],
         TargetType targetType) const;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
LocalFeatureTempReflection::LocalFeatureTempReflection(int timeout): timeout_(timeout) {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
LocalFeatureTempReflection::~LocalFeatureTempReflection() {
}
//+------------------------------------------------------------------+

bool LocalFeatureTempReflection::match(
         int start,
         int index,
         const Candle &candles[],
         LocalFeature& result) const {
    
    // 処理の範囲チェック
    if (ArraySize(candles) <= index + 3) {
        return false;
    }
    
    // 注目ローソク足
    Candle cur = candles[index];
    if (cur.type_ == CANDLE_TYPE_CROSS) {
        return false;
    }
    TargetType preType = cur.isUp() ? UP_CANDLE : DOWN_CANDLE;
    int preIndex = findTargetCandle(index+1, index+timeout_, candles, preType);
    if (preIndex < 1) {
        return false;
    }
    int pre2Index = preIndex + 1;
    if (ArraySize(candles) <= pre2Index) {
        return false;
    }
    int pre3Index = pre2Index + 1;
    if (ArraySize(candles) <= pre3Index) {
        return false;
    }
    
    // 注目ローソク足の一つ前
    Candle pre = candles[preIndex];
    // 注目ローソク足の二つ前
    Candle pre2 = candles[pre2Index];
    // 注目ローソク足の三つ前
    Candle pre3 = candles[pre3Index];
    
    if (!isTarget(cur, pre, pre2, pre3)) {
        return false;
    }
    
    if (cur.isUp()) {
        // 比較足の大きな陰線に対して一時的に陽線が2回反発した場合
        result.type_ = LOCAL_FEATURE_MIN;
        result.featureStart_ = cur.index_;
        result.featureEnd_ = pre2.index_;
    } else if (cur.isDown()) {
        // 比較足の大きな陽線に対して一時的に陰線が2回反発した場合
        result.type_ = LOCAL_FEATURE_MAX;
        result.featureStart_ = cur.index_;
        result.featureEnd_ = pre2.index_;
    } else {
        return false;
    }
    
    return true;
}

bool LocalFeatureTempReflection::isTarget(const Candle& cur, const Candle& pre, const Candle& pre2, const Candle& pre3) const {
    // pre2がpre3に含まれているかチェック
    if (pre3.realBodyLow() <= pre2.realBodyLow() && pre2.realBodyHigh() <= pre3.realBodyHigh()) {
        return false;
    }

    bool isValidOrder = (cur.isUp() && pre.isUp() && pre2.isDown()) ||
                        (cur.isDown() && pre.isDown() && pre2.isUp());
    // ローソク足の並び順チェック
    if (!isValidOrder) return false;

    if (cur.isUp()) {
        // 前回の高値更新は成功しているが前々回の高値更新に失敗しているか
        return cur.realBodyHigh() < pre2.realBodyHigh() && pre.realBodyHigh() < cur.realBodyHigh();        
    } else if (cur.isDown()) {
        // 前回の安値更新は成功しているが前々回の安値更新に失敗しているか
        return pre2.realBodyLow() < cur.realBodyLow() && cur.realBodyLow() < pre.realBodyLow();
    }

    return false;    
}

int LocalFeatureTempReflection::findTargetCandle(
         int start, int end, 
         const Candle &candles[],
         TargetType targetType) const {
     int foundIndex = -1;
     int n = ArraySize(candles);
     for (int idx = start; idx <= end && idx < n; idx++) {
         Candle c = candles[idx];
         if (targetType == UP_CANDLE && c.isUp()) {
             return idx;
         }
         else if (targetType == DOWN_CANDLE && c.isDown()) {
             return idx;
         }
     }
     
     return foundIndex;
}
