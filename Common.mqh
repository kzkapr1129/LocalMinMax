//+------------------------------------------------------------------+
//|                                                       Common.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

enum UserError {
    ERR_NONE            = 0x0000,
    ERR_OUT_OF_MEMORY   = 0x8001,
    ERR_IN_BUILDIN_FUNC = 0x8002,
    ERR_INVALID_INDEX   = 0x8003,
};

enum CandleType {
   CANDLE_TYPE_CROSS      = 0x8000,
   CANDLE_TYPE_UP_CROSS   = 0x8001,
   CANDLE_TYPE_DOWN_CROSS = 0x8002,
   CANDLE_TYPE_UP         = 0x0001,
   CANDLE_TYPE_DOWN       = 0x0002,
};

struct Candle {
   int index_;
   CandleType type_;
   datetime time_;
   double open_;
   double high_;
   double low_;
   double close_;

    Candle() : index_(-1), type_(CANDLE_TYPE_CROSS), time_(0), open_(0),
        high_(0), low_(0), close_(0) {
    }
        
    Candle(int index, datetime time, double open, double high, double low, double close)
       : index_(index), time_(time), open_(open), high_(high), low_(low), close_(close) {
        type_ = GetCandleType();
    }

    // 実体の長さを返却する
    double lengthRealBody() const {
        return MathAbs(open_ - close_);
    }
   
    // 上ヒゲの長さを返却する
    double lengthUpperShadow() const {
        return open_ < close_ ? high_ - close_ : high_ - open_;
    }
   
    // 下ヒゲの長さを返却する
    double lengthLowerShadow() const {
        return open_ < close_ ? open_ - low_ : close_ - low_;
    }
   
    // 上下のヒゲの長さを返却する
    double lengthShadow() const {
        return lengthUpperShadow() + lengthLowerShadow();
    }
    
    double realBodyHigh() const {
        return open_ < close_ ? close_ : open_;
    }
    
    double realBodyLow() const {
        return open_ < close_ ? open_ : close_;
    }
    
    bool isCross() const {
        return (type_ & 0x8000) != 0;
    }
    
    bool isUp() const {
        return (type_ & 0x0001) != 0;
    }
    
    bool isDown() const {
        return (type_ & 0x0002) != 0;
    }
    
    CandleType GetCandleType() const {
        double lenRealBody = lengthRealBody();
        if (lenRealBody == 0.0) {
            return CANDLE_TYPE_CROSS;
        }
        else if (1.6 <= MathLog(lengthShadow() / lenRealBody)) {
            if (open_ < close_) {
                return CANDLE_TYPE_UP_CROSS;
            } else {
                return CANDLE_TYPE_DOWN_CROSS;
            }
        } else if (open_ < close_) {
            return CANDLE_TYPE_UP;
        } else if (close_ < open_) {
            return CANDLE_TYPE_DOWN;
        } else {
            Print("invalid case in Candle.GetCandleType()", index_, open_, close_);
            return CANDLE_TYPE_CROSS;
        }
    }
};

int makeCandles(Candle &candles[], string symbol, ENUM_TIMEFRAMES timeframe) { 
    // バー数を取得する
    int numBars = iBars(symbol, timeframe);
    return makeCandles(candles, symbol, timeframe, numBars);
}

int makeCandles(Candle &candles[], string symbol, ENUM_TIMEFRAMES timeframe, int numBars) {
    if (numBars < 1) {
        return ERR_IN_BUILDIN_FUNC;
    }
    
    // ローソク足格納用バッファのメモリ確保
    if (ArrayResize(candles, numBars) < 0) {
        return ERR_OUT_OF_MEMORY;
    }
    
    int last = numBars - 1;
    // 最新値から過去に向かってローソク足を作成する
    for (int shift = 0; shift < numBars; shift++) {
        datetime time = iTime(symbol, timeframe, shift);
        double open   = iOpen(symbol, timeframe, shift);
        double high   = iHigh(symbol, timeframe, shift);
        double low    = iLow(symbol, timeframe, shift);
        double close  = iClose(symbol, timeframe, shift);
        
        Candle c(shift, time, open, high, low, close);
        candles[shift] = c;
    }

    return ERR_NONE;
} 