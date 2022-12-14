//+------------------------------------------------------------------+
//|                                                 LineDetector.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Common.mqh"
#include "../LocalFeature/LocalFeatureMatcher.mqh"

/**
 * 局所特徴を利用したライン検出機のインタフェース
 */
interface ILineDetector {
public:
    bool detect(int start,
                int limit,
                const Candle &candles[],
                const LocalFeature& localFeatures[],
                Line2D &results[]) const;
};
