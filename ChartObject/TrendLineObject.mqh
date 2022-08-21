//+------------------------------------------------------------------+
//|                                              TrendLineObject.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "ChartObject.mqh"

/**
 * チャートにトレンドラインを描画するチャートオブジェクト
 */
class TrendLineObject : public ChartObject {
public:
    TrendLineObject(datetime sx, double sy, datetime ex, double ey, int chartId = 0, int subChartId = 0);
    ~TrendLineObject();

    bool createChartObject();
    
private:
    datetime sx_;
    double   sy_;
    datetime ex_;
    double   ey_;
};

/**
 * コンストラクタ
 * @param chartId チャートID
 * @param subChartId サブチャートID
 */
TrendLineObject::TrendLineObject(datetime sx, double sy, datetime ex, double ey, int chartId, int subChartId)
    : ChartObject(chartId, subChartId), sx_(sx), sy_(sy), ex_(ex), ey_(ey) {
}

/**
 * デストラクタ
 */
TrendLineObject::~TrendLineObject() {
}

/**
 * チャートオブジェクトを作成する
 * @return チャートオブジェクトの作成に成功した場合はtrueを返却し、それ以外はfalseを返却する。
 */
bool TrendLineObject::createChartObject() {
    return ObjectCreate(chartId_, objectName_, OBJ_TREND, subChartId_, sx_, sy_, ex_, ey_);
}
