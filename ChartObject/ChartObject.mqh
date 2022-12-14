//+------------------------------------------------------------------+
//|                                                  ChartObject.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

/**
 * チャートオブジェクトのベースクラス
 */
class ChartObject {
public:
    virtual ~ChartObject();

    bool show(bool redraw = true);
    bool hide(bool redraw = true);

protected:
    ChartObject(int chartId = 0, int subChartId = 0);

    virtual bool createChartObject() = 0;

    int chartId_;
    int subChartId_;
    string objectName_;
    
private:
    static int cnt_;
};

int ChartObject::cnt_ = 0;

/**
 * デストラクタ
 */
ChartObject::~ChartObject() {
}

/**
 * チャート上にオブジェクトを表示させる
 * @param redraw チャートオブジェクト作成後に画面の再描画を行うかのフラグ値。
 * @return 表示に成功した場合はtrueを返却し、それ以外はfalseを返却する。
 */
bool ChartObject::show(bool redraw) {
    // チャートオブジェクト(派生クラス実装)を作成する
    bool success = createChartObject();
    if (success && redraw) {
        // チャートの再描画
        ChartRedraw(chartId_);
    }
    return success;
}

/**
 * チャート上に表示したオブジェクトを消す
 * @param redraw チャートオブジェクト削除後に画面の再描画を行うかのフラグ値。
 * @return 削除に成功した場合はtrueを返却し、それ以外はfalseを返却する。
 */
bool ChartObject::hide(bool redraw) {
    bool success = ObjectDelete(chartId_, objectName_);
    if (success && redraw) {
        // チャートの再描画
        ChartRedraw(chartId_);
    }
    return success;
}

/**
 * コンストラクタ
 * @param chartId チャートオブジェクトを表示させるチャートのID
 * @param subchartId サブチャートのID
 */
ChartObject::ChartObject(int chartId, int subChartId) : chartId_(chartId), subChartId_(chartId) {
    objectName_ = StringFormat("chart-obj-%d", cnt_++);
}
