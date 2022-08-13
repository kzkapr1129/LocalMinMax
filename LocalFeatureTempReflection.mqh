//+------------------------------------------------------------------+
//|                              ChartPatternTemporaryReflection.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Common.mqh"
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
         const datetime &time[],
         const double &open[],
         const double &high[],
         const double &low[],
         const double &close[],
         LocalFeature& result) const;
         
private:
    bool isTarget(const Candle& c, const Candle& pre, const Candle& pre2, const Candle& pre3) const;
    int findTargetCandle(int start, int end,
         const datetime &time[],
         const double &open[],
         const double &high[],
         const double &low[],
         const double &close[],
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

/*
bool ChartPatternTemporaryReflection::match(
         int start,
         int index,
         int last,
         const datetime &time[],
         const double &open[],
         const double &high[],
         const double &low[],
         const double &close[],
         MatchResult& result) const {
    
    // 処理の範囲チェック
    if (index - 3 < 0) {
        return false;
    }
    
    Candle c1(index, time[index], open[index], high[index], low[index], close[index]);
    Candle c2(index-1, time[index-1], open[index-1], high[index-1], low[index-1], close[index-1]);
    
    result.valueInt_ = c1.index_;
    result.valueType_ = VALUE_TYPE_INDEX;
    result.valueDouble_ = coverRate(c1, c2);
    
    return true;
}
*/

bool LocalFeatureTempReflection::match(
         int start,
         int index,
         const datetime &time[],
         const double &open[],
         const double &high[],
         const double &low[],
         const double &close[],
         LocalFeature& result) const {
    
    // 処理の範囲チェック
    if (index - 3 < 0) {
        return false;
    }
    
    // 注目ローソク足
    Candle cur(index, time[index], open[index], high[index], low[index], close[index]);
    if (cur.type_ == CANDLE_TYPE_CROSS) {
        return false;
    }
    TargetType preType = cur.isUp() ? UP_CANDLE : DOWN_CANDLE;
    int preIndex = findTargetCandle(index-1, index-timeout_, time, open, high, low, close, preType);
    if (preIndex < 1) {
        return false;
    }
    int pre2Index = preIndex - 1;
    if (pre2Index < 1) {
        return false;
    }
    int pre3Index = pre2Index-1;
    if (pre3Index < 1) {
        return false;
    }
    
    // 注目ローソク足の一つ前
    Candle pre(preIndex, time[preIndex], open[preIndex], high[preIndex], low[preIndex], close[preIndex]);
    // 注目ローソク足の二つ前
    Candle pre2(pre2Index, time[pre2Index], open[pre2Index], high[pre2Index], low[pre2Index], close[pre2Index]);
    // 注目ローソク足の三つ前
    Candle pre3(pre3Index, time[pre3Index], open[pre3Index], high[pre3Index], low[pre3Index], close[pre3Index]);
    
    if (!isTarget(cur, pre, pre2, pre3)) {
        return false;
    }
    
    if (cur.isUp()) {
        // 比較足の大きな陰線に対して一時的に陽線が2回反発した場合
        result.type_ = LOCAL_FEATURE_MIN;
        result.featureStart_ = pre2.index_;
        result.featureEnd_ = cur.index_;
    } else if (cur.isDown()) {
        // 比較足の大きな陽線に対して一時的に陰線が2回反発した場合
        result.type_ = LOCAL_FEATURE_MAX;
        result.featureStart_ = pre2.index_;
        result.featureEnd_ = cur.index_;
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
         const datetime &time[],
         const double &open[],
         const double &high[],
         const double &low[],
         const double &close[],
         TargetType targetType) const {
     int foundIndex = -1;
     for (int idx = start; 1 <= idx && end <= idx; idx--) {
         Candle c(idx, time[idx], open[idx], high[idx], low[idx], close[idx]);
         if (targetType == UP_CANDLE && c.isUp()) {
             return idx;
         }
         else if (targetType == DOWN_CANDLE && c.isDown()) {
             return idx;
         }
     }
     
     return foundIndex;
}
