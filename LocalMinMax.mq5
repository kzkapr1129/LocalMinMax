//+------------------------------------------------------------------+
//|                                                  LocalMinMax.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots   5 

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

#property indicator_label3 "ShortSMA" 
#property indicator_type3   DRAW_LINE 
#property indicator_color3 clrRed 
#property indicator_style3 STYLE_SOLID 
#property indicator_width3  1 

#property indicator_label4 "MiddleSMA" 
#property indicator_type4   DRAW_LINE 
#property indicator_color4 clrBlue
#property indicator_style4 STYLE_SOLID 
#property indicator_width4  1 

#property indicator_label5 "LongSMA" 
#property indicator_type5   DRAW_LINE 
#property indicator_color5 clrWhite
#property indicator_style5 STYLE_SOLID 
#property indicator_width5  1 

double SignalUpBuffer[]; 
double SignalDownBuffer[]; 
double ShortSMABuffer[]; 
double MiddleSMABuffer[]; 
double LongSMABuffer[]; 

#include "Detector\LocalFeature\LocalFeaturePriceUpdate.mqh"
#include "Detector\LocalFeature\LocalFeatureTempReflection.mqh"
#include "Detector\Reflection\SMAReflectionDetector.mqh"
#include "Detector\Reflection\LineDetector.mqh"
#include "ChartObject\TrendLineObject.mqh"

const LocalFeaturePriceUpdate Feature1(3);
const LocalFeatureTempReflection Feature2(2);
const ILocalFeatureMatcher* Matcher[] = { &Feature1, &Feature2 };
const int NumMatchers = sizeof(Matcher) / sizeof(ILocalFeatureMatcher*);

const int Averages[] = {20, 50, 100};
const SMAReflectionDetector ReflectionDetector(Averages, 0.33, 0.000002, 0.0);

datetime lastDate = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,SignalUpBuffer,INDICATOR_DATA); 
   SetIndexBuffer(1,SignalDownBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ShortSMABuffer,INDICATOR_DATA);
   SetIndexBuffer(3,MiddleSMABuffer,INDICATOR_DATA);
   SetIndexBuffer(4,LongSMABuffer,INDICATOR_DATA);
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
    if (lastDate == time[rates_total-2]) {
        return prev_calculated;
    }
    lastDate = time[rates_total-2];
                
    ObjectsDeleteAll(0, -1);

    int si = rates_total - 1 - 10;
    int ei = rates_total - 1 - 20;
    int exti = rates_total - 1 - 0;
    datetime sx = time[si];
    double   sy = close[si];
    datetime ex = time[ei];
    double   ey = close[ei];
    Line2D l(sx, sy, ex, ey);
    double xy = l.extend(time[exti]);
    TrendLineObject tl(l.e_, Point2D(time[exti], xy));
    tl.show();

    
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
        ShortSMABuffer[i] = 0;
        MiddleSMABuffer[i] = 0;
        LongSMABuffer[i] = 0;
    
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
    
    int numFeatures = ArraySize(features);
    if (numFeatures <= 0) {
        return(rates_total);
    }
    
    LocalFeatureFactors factors[];
    if (ArrayResize(factors, numFeatures) < 0) {
        return(rates_total);
    }
    
    ReflectionDetector.detect(0, numBars, candles, features, factors);
    
    int n = ArraySize(candles);
    for (int i = 0; i < numFeatures; i++) {
        LocalFeature lf = features[i];
        for (int j = lf.featureStart_; j <= lf.featureEnd_; j++) {
            if (0 < lf.type_) {
                SignalUpBuffer[n - j - 1] = (double)lf.type_;
            } else {
                SignalDownBuffer[n - j - 1] = (double)lf.type_;
            }
            
        }
        
        LocalFeatureFactors ft = factors[i];
        if (0 < ArraySize(ft.values_)) {
            LocalFeatureFactor topFactor = ft.values_[0];
            switch (topFactor.subType_) {
            case 0: {
                    for (int j = topFactor.factorStart_; j <= topFactor.factorEnd_; j++) {
                        ShortSMABuffer[n - j - 1] = (double)(lf.type_) * 0.8;
                    }
                }
                break;
            case 1: {
                    for (int j = topFactor.factorStart_; j <= topFactor.factorEnd_; j++) {
                        MiddleSMABuffer[n - j - 1] = (double)(lf.type_) * 0.8;
                    }
                }
                break;
            case 2: {
                    for (int j = topFactor.factorStart_; j <= topFactor.factorEnd_; j++) {
                        LongSMABuffer[n - j - 1] = (double)(lf.type_) * 0.8;
                    }
                }
                break;
            }
        }
    }
    
    for (int i = 0; i < ArraySize(factors); i++) {
        ArrayFree(factors[i].values_);
    }
    ArrayFree(factors);
    ArrayFree(features);
    ArrayFree(candles);
                        
//--- return value of prev_calculated for next call
    return(rates_total);
}
//+------------------------------------------------------------------+
