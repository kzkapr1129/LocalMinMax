//+------------------------------------------------------------------+
//|                                                  LocalMinMax.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 2
#property indicator_plots   2 

#property indicator_label1 "SignalUp" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1 clrPink 
#property indicator_style1 STYLE_SOLID 
#property indicator_width1  1 

#property indicator_label2 "SignalDown" 
#property indicator_type2   DRAW_LINE 
#property indicator_color2 clrAqua 
#property indicator_style2 STYLE_SOLID 
#property indicator_width2  1 

double SignalUpBuffer[]; 
double SignalDownBuffer[]; 

#include "LocalFeaturePriceUpdate.mqh"
#include "LocalFeatureTempReflection.mqh"
#include "SMAReflectionDetector.mqh"

const LocalFeaturePriceUpdate Feature1(3);
const LocalFeatureTempReflection Feature2(2);
const ILocalFeatureMatcher* Matcher[] = { &Feature1, &Feature2 };
const int NumMatchers = sizeof(Matcher) / sizeof(ILocalFeatureMatcher*);

int Averages[] = {20, 50, 100};
const SMAReflectionDetector ReflectionDetector(Averages, 0.33, 0.000002, 0.0);

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,SignalUpBuffer,INDICATOR_DATA); 
   SetIndexBuffer(1,SignalDownBuffer,INDICATOR_DATA); 
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
                
    int start = prev_calculated + 1;
    if (rates_total <= start) {
        return rates_total;
    }
                
//---
    Candle candles[];
    int err = makeCandles(candles, NULL, 0);
    if (err != ERR_NONE) {
        Alert(StringFormat("Occured Error: %#4x, (%d)", err, __LINE__));
        return rates_total;
    }

    LocalFeature features[];
    int numBars = ArraySize(candles);    
    for (int i = numBars-1; 0 <= i; i--) {
        SignalUpBuffer[i] = 0;
        SignalDownBuffer[i] = 0;
    
        for (int j = 0; j < NumMatchers; j++) {
            LocalFeature feature;
            bool foundPattern = Matcher[j].match(0, i, candles, feature);
            if (foundPattern) {
                bool reject = false;
                int n = ArraySize(features);
                if (n != 0) {
                    LocalFeature preFeature = features[n-1];
                    // 局所特徴の種類が一致しており、前回の範囲に含まれる場合は除外対象
                    reject = feature.featureStart_ <= preFeature.featureEnd_ &&
                             preFeature.featureEnd_ <= feature.featureEnd_ &&
                             feature.type_ == preFeature.type_;
                }
                if (!reject) {
                    if (ArrayResize(features, n + 1) < 0) {
                        Alert(StringFormat("Occured Error: %#4x (%d)", err, __LINE__));
                        ArrayFree(features);
                        ArrayFree(candles);
                        return rates_total;
                    }
                    features[n] = feature;
                }
            }
        }
    }
    
    int n = ArraySize(candles);
    for (int i = 0; i < ArraySize(features); i++) {
        LocalFeature lf = features[i];
        for (int j = lf.featureStart_; j <= lf.featureEnd_; j++) {
            if (0 < lf.type_) {
                SignalUpBuffer[n - j - 1] = (double)lf.type_;
            } else {
                SignalDownBuffer[n - j - 1] = (double)lf.type_;
            }
            
        }
        PrintFormat("[%d] %04d - %04d: %f", i, lf.featureStart_, lf.featureEnd_, (double)lf.type_);
    }
    
    ArrayFree(features);
    ArrayFree(candles);
                        
//--- return value of prev_calculated for next call
    return(rates_total);
}
//+------------------------------------------------------------------+
