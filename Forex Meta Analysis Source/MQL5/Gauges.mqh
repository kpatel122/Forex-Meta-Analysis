//+------------------------------------------------------------------+
//|                                               MetaIndicators.mqh |
//|                                                       KP Systems |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KP Systems"
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
enum GAUGE_RESULT
{
   SELL = 0,
   BUY = 1,
   NEUTRAL = 2,
   NONE  = 3,
   GAUGE_RESULT_MAX_SIZE = 4
};

enum GAUGE_SENTIMENT
{
   NORMAL=4,
   STRONG = 5,
   NO_SENTIMENT = 6
};

enum TIME_FRAME
{
   M5 = 0,
   M15 = 1,
   M30 = 2,
   H1 = 3,
   D1 = 4,
   TIME_FRAME_SIZE = 5
};



enum RESULT
{
   FAILURE = 0,
   SUCCESS = 1
};

enum GAUGES
{
   RSI = 0,
   STOCH = 1,
   MA5 = 2,
   MA10 = 3,
   MAX_GAUGES = 4
};


//enum GAUGES_MAS
//{
  
//   MAX_MAS = 0,
    
//};







enum GAUGE_TYPE
{
   INDICATOR =0,
   MOVING_AVERAGE = 1,
   MAX_GAUGE_TYPE_SIZE =2
};

//#define MAX_GAUGES 1

RESULT ASSERT(bool condition,string message)
{
   RESULT res = SUCCESS;   
   
   if(!condition)
   {
     string msg = "ASSERT FAILED " + message + " "+ IntegerToString(GetLastError());
     Print(msg);
     //Alert(msg);
     res = FAILURE;
   }
   return res;
}

ENUM_TIMEFRAMES MapTimeFrameIndex(TIME_FRAME timeframe)
{
   switch(timeframe)
   {
      case M5: {return PERIOD_M5;}break;
      case M15: {return PERIOD_M15;}break;
      case M30: {return PERIOD_M30;}break;
      case H1: {return PERIOD_H1;}break;
      case D1: {return PERIOD_D1;}break;
      default: { ASSERT(false,"Unkown time frame in MapTimeFrameIndex " +  IntegerToString(timeframe)); }break;
   }
    return -1;
}

string MapTimeFrameString(TIME_FRAME timeframe)
{
   switch(timeframe)
   {
      case M5: {return "M5";}break;
      case M15: {return "M15";}break;
      case M30: {return "M30";}break;
      case H1: {return "H1";}break;
      case D1: {return "D1";}break;
      default: { ASSERT(false,"Unkown time frame in MapTimeFrameIndex " +  IntegerToString(timeframe)); return NULL; }break;
   }
    return NULL;
}

string MapGaugeResultString(GAUGE_RESULT result)
{

   static string GaugeResultLookup[GAUGE_RESULT_MAX_SIZE];
   GaugeResultLookup[SELL] = "SELL";GaugeResultLookup[BUY] = "BUY";GaugeResultLookup[NEUTRAL] = "NEUTRAL";GaugeResultLookup[NONE] = "NONE";
   
   if(ASSERT( (result>=0 && result < GAUGE_RESULT_MAX_SIZE),"Gauge result to string out of bounds")==SUCCESS)
      return(GaugeResultLookup[result]);
   
    return NULL;
}




//guage cn be an indicator or a ma
//specific guage is in the derive class
//handle is in the base data buffers in the derived as there can be more than one data buffer
class CGauge
{
   protected:
   GAUGE_TYPE type; //indicator or ma
   GAUGE_RESULT result[TIME_FRAME_SIZE];
   string additional[TIME_FRAME_SIZE];
   int handle[TIME_FRAME_SIZE];
  
   string value_string[TIME_FRAME_SIZE];
   string name; //rsi,adx,ma5 etc
   string guage_symbol;//usdgbp,eurousd etc
   //string guage_timeframe[TIME_FRAME_SIZE];
   
   
   public:
   CGauge(string _name, string _symbol) : name(_name),guage_symbol(_symbol) {}
   CGauge(); //values set with initialise function if constructor params are omitted
   ~CGauge(){ReleaseHandle();}
   
   string GetName() { return name;}
   string GetValue(TIME_FRAME time_frame) {return value_string[time_frame];}
   string GetGaugeSymbol() { return guage_symbol; }
   
   GAUGE_TYPE GetType() {return type;}
   
   GAUGE_RESULT GetSentiment(TIME_FRAME timeframe) { return result[timeframe];}
   
   void Initialize(string _name, string _symbol){name = _name;guage_symbol = _symbol;}
   
   
   virtual void Calculate(){ ASSERT(false,"Called based calculate");}//shouldnt happen
   virtual void GetHandle() {ASSERT(false,"Called based get handle");} //shoudlnt happen
 
   
   void ReleaseHandle(){ for(int i=0;i<TIME_FRAME_SIZE;i++) IndicatorRelease(handle[i]);}
   
};

class CGaugeRSI: public CGauge
{
    public:
    int period;
    CGaugeRSI(string _symbol,int _period):CGauge("RSI",_symbol),period(_period) {}
    ~CGaugeRSI() {}
    void Calculate();
    void GetHandle();

};

void CGaugeRSI::GetHandle(void)
{
    
   ENUM_TIMEFRAMES tframe;
   for(int i=0;i<TIME_FRAME_SIZE;i++)
   {
      tframe = MapTimeFrameIndex((TIME_FRAME)i);
      handle[i] = iRSI(guage_symbol,tframe,period,PRICE_CLOSE);
      ASSERT(handle[i] !=INVALID_HANDLE,"Invalid RSI handle");
   }
   type = INDICATOR;
}
void CGaugeRSI::Calculate(void)
{
   //read data
   double rsival[1];
   double normalized_rsi = 0;
   
   for(int time_frame=0;time_frame<TIME_FRAME_SIZE;time_frame++)
   {
      if(ASSERT(CopyBuffer(handle[time_frame],0,0, 1, rsival) >=1,"Could not get RSI data timeframe " + IntegerToString(time_frame))==SUCCESS)
      {
         normalized_rsi =  NormalizeDouble(rsival[0],2);      // number of digits after decimal point 
         value_string[time_frame] = DoubleToString(normalized_rsi,2); 
         //calculate result
         if(rsival[0] >50)result[time_frame] = BUY;
         else if(rsival[0] <50)result[time_frame] = SELL;
         else result[time_frame] = NEUTRAL;
      }
   }
   
}
//tmp
class CGaugeStoch: public CGauge
{
    public:
    CGaugeStoch(string _symbol):CGauge("STOCH",_symbol) {}
    void Calculate();
    void GetHandle();
};

void CGaugeStoch::GetHandle(void)
{
   type = INDICATOR;
}
void CGaugeStoch::Calculate(void)
{

   for(int time_frame=0;time_frame<TIME_FRAME_SIZE;time_frame++)
   {
        value_string[time_frame] = "0.5";
        result[time_frame] = BUY;
   }
}


//tmp
class CGaugeMA5: public CGauge
{
    public:    
    CGaugeMA5(string _symbol):CGauge("MA5",_symbol) {}
    void Calculate();
    void GetHandle();

};
void CGaugeMA5::GetHandle(void)
{
   type = MOVING_AVERAGE;
}
void CGaugeMA5::Calculate(void)
{
   for(int time_frame=0;time_frame<TIME_FRAME_SIZE;time_frame++)
   {
      result[time_frame] = SELL;
      value_string[time_frame] = "30.3"; 
   }
}
//tmp
class CGaugeMA10: public CGauge
{
    public:    
    CGaugeMA10(string _symbol):CGauge("MA10",_symbol) {}
    void Calculate();
    void GetHandle();

};
void CGaugeMA10::GetHandle(void)
{
   type = MOVING_AVERAGE;
}
void CGaugeMA10::Calculate(void)
{
   for(int time_frame=0;time_frame<TIME_FRAME_SIZE;time_frame++)
   {
      result[time_frame] = SELL;
      value_string[time_frame] = "15.5"; 
   }
}