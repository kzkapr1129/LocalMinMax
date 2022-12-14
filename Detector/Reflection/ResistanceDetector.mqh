//+------------------------------------------------------------------+
//|                                           ReflectionDetector.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

enum Resistance {
    None = -1,
    SMAShort,
    SMAMiddle,
    SMALong,
    NumResistances,
};

struct ResistanceInfo {
    Resistance type_;
    double price_;
    
    ResistanceInfo() : type_(None), price_(0) {
    }
};

#define NumRanking 3
struct Ranking {
    ResistanceInfo ranking[NumRanking];
    
    void pushOrderAsc(const ResistanceInfo &info) {
        int pushPos = -1;
        // 挿入位置を探す
        for (int i = 0; i < NumRanking; i++) {
            if (ranking[i].type_ == None || info.price_ < ranking[i].price_) {
                if (ranking[i].type_ != None) {
                    // 挿入位置以降を後ろにずらす
                    for (int j = NumRanking - 1; i <= j - 1; j--) {
                        ranking[j] = ranking[j-1]; 
                    }
                }
                // 挿入位置に挿入
                ranking[i] = info;
                break;
            }
        }
    }
    
    void pushOrderDsc(const ResistanceInfo& info) {
            int pushPos = -1;
        // 挿入位置を探す
        for (int i = 0; i < NumRanking; i++) {
            if (ranking[i].type_ == None || ranking[i].price_ < info.price_) {
                if (ranking[i].type_ != None) {
                    // 挿入位置以降を後ろにずらす
                    for (int j = NumRanking - 1; i <= j - 1; j--) {
                        ranking[j] = ranking[j-1]; 
                    }
                }
                // 挿入位置に挿入
                ranking[i] = info;
                break;
            }
        }
    }
};

struct DetectResult {
    Ranking results_[];
};

interface IResistanceDetector {
public:
    // 戻り値は検出した個数
    int detect(const double& signals[], int start, int limit, 
         const datetime &time[],
         const double &open[],
         const double &high[],
         const double &low[],
         const double &close[],
         DetectResult& result);
};
