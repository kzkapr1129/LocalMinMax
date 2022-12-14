//+------------------------------------------------------------------+
//|                                            TrendLineDetector.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "LineDetector.mqh"

/**
 * トレンドライン検出機
 */
class TrendLineDetector : public ILineDetector {
public:
    TrendLineDetector();
    ~TrendLineDetector();

    bool detect(int start,
                    int limit,
                    const Candle &candles[],
                    const LocalFeature& localFeatures[],
                    Line2D &results[]) const;
};

/**
 * コンストラクタ
 */
TrendLineDetector::TrendLineDetector() {
}

/**
 * デストラクタ
 */
TrendLineDetector::~TrendLineDetector() {
}

/**
 * 局所特徴からトレンドラインを検出する。
 * @param [in] start 検査を開始するインデックス
 * @param [in] limit 検査を終了するインデックス
 * @param [in] localFeatures 局所特徴のリスト
 * @param [out] results 検出したトレンドライン
 * @return 検出処理中に何らかの問題が発生した場合はfalseを返却し、成功した場合はtrueを返却する。検出件数が0件であっても成功とみなす。
 */
bool TrendLineDetector::detect(int start,
                    int limit,
                    const Candle &candles[],
                    const LocalFeature& localFeatures[],
                    Line2D &results[]) const {
                  
    ArrayFree(results);  
    ArrayResize(results, 1);
    datetime sx = candles[0].time_;
    double   sy = candles[0].close_;
    datetime ex = candles[10].time_;
    double   ey = candles[10].close_;
    results[0] = Line2D(sx, sy, ex, ey);
    return true;
}