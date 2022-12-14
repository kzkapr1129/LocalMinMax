//+------------------------------------------------------------------+
//|                                      ChartPatternPriceUpdate.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Common.mqh"
#include "LocalFeatureMatcher.mqh"

/**
 * 局所的特徴の検出器: 比較ローソク足に対して完全な反発(安値、または高値更新)を検出する
 */
class LocalFeaturePriceUpdate : public ILocalFeatureMatcher {
private:
    int timeout_;

public:
    LocalFeaturePriceUpdate(int timeout);
    ~LocalFeaturePriceUpdate();

    bool match(
         int start,
         int index,
         const Candle &candles[],
         LocalFeature& result) const;

private:
    bool isTargetCandle(const Candle& c) const;
    int  findCompareTarget(int preStart,
         const Candle &candles[],
         const Candle& c) const;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
LocalFeaturePriceUpdate::LocalFeaturePriceUpdate(int timeout) : timeout_(timeout) {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
LocalFeaturePriceUpdate::~LocalFeaturePriceUpdate() {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LocalFeaturePriceUpdate::match(
         int start,
         int index,
         const Candle &candles[],
         LocalFeature& result) const {
    
    Candle c = candles[index];
    
    // 注目ローソク足が対象外か判定する
    if (!isTargetCandle(c)) {
        // 実体よりヒゲの長さが長い、または実体がない場合
        return false;
    }
    
    // 注目ローソク足の比較足を検索する
    int preTargetIndex = findCompareTarget(index+1, candles, c);
    if (preTargetIndex < 0) {
        // 比較対象が見つからなかった場合
        return false;
    }
    
    // 注目ローソク足と比較ローソク足間で最高値または最安値を探す
    bool isUpCandle = c.type_ == CANDLE_TYPE_UP;
    if (isUpCandle) {
        // 注目ローソク足が比較足の高値更新をした(谷の形が出来た)
        result.type_ = LOCAL_FEATURE_MIN;
        result.featureStart_ = c.index_;
        result.featureEnd_   = preTargetIndex;
    } else {
        // 注目ローソク足が比較足の安値を更新した(山の形が出来た)
        result.type_ = LOCAL_FEATURE_MAX;
        result.featureStart_ = c.index_;
        result.featureEnd_   = preTargetIndex;        
    }

    return true;
}

bool LocalFeaturePriceUpdate::isTargetCandle(const Candle& c) const {
    return !c.isCross();
}

int LocalFeaturePriceUpdate::findCompareTarget(int preStart, const Candle &candles[], const Candle& c) const {
    // 注目ローソク足から過去に遡って、陽線なら陰線・陰線なら陽線を検索する
    int n = ArraySize(candles);
    for (int i = 0; i < timeout_; i++) {
        int preIndex = preStart + i;
        if (n <= preIndex) {
            return -1;
        }
                
        Candle pre = candles[preIndex];
        if (!pre.isCross() && c.type_ != pre.type_) {
            // 注目ローソク足の逆のローソク足(陽線なら陰線・陰線なら陽線)を見つけたとき
            if (c.type_ == CANDLE_TYPE_UP) {
                return pre.open_ < c.close_ ? preIndex : -1;
            } else if (c.type_ == CANDLE_TYPE_DOWN) {
                return c.close_ < pre.open_ ? preIndex : -1;
            }
        }
    }
    return -1;
}

//+------------------------------------------------------------------+
