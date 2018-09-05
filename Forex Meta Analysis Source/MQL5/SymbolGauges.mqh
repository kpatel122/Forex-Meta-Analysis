//+------------------------------------------------------------------+
//|                                                 SymbolGauges.mqh |
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

#include <Gauges.mqh>

enum SYMBOL_PAIR
{
   EURUSD = 0,
   GBPUSD = 1,
   GBPJPY = 2,
   USDJPY = 3,
   SYMBOL_SIZE = 4
};

enum SUMMARY_STATUS
{
   SUMMARY_BUY = 0,
   SUMMARY_SELL =1,
   SUMMARY_STRONG_BUY=2,
   SUMMARY_STRONG_SELL =3,
   SUMMARY_NEUTRAL=4,
   SUMMARY_MAX_SIZE=5
   
};
 
string MapSummaryStatusString(SUMMARY_STATUS status)
{
   static string lookup[SUMMARY_MAX_SIZE];
   lookup[SUMMARY_BUY]="Buy";lookup[SUMMARY_SELL]="Sell";lookup[SUMMARY_STRONG_BUY]="Strong Buy";lookup[SUMMARY_STRONG_SELL]="Strong Sell";lookup[SUMMARY_NEUTRAL]="Neutral";
   
   if(ASSERT(status>=0 && status <SUMMARY_MAX_SIZE,"Map Summary status out of bounds") == SUCCESS)
      return lookup[status];
      
   return "Invalid MapSummaryStatusString";
   
   
}

string MapSymbolEnum(SYMBOL_PAIR symbol)
{

   switch(symbol)
   {
      case EURUSD: {return "EURUSD";}break;
      case GBPUSD: {return "GBPUSD";}break;
      case GBPJPY: {return "GBPJPY";}break;
      case USDJPY: {return "USDJPY";}break;
      
      default: { ASSERT(false,"Unkown symbol in MapSymbolIndex " +  IntegerToString(symbol)); return NULL; }break;
   }
    return NULL;
}


class CSentimentCounters
{
   public:
   int buy[MAX_GAUGE_TYPE_SIZE];
   int sell[MAX_GAUGE_TYPE_SIZE];
   int neutral[MAX_GAUGE_TYPE_SIZE];
   
   CSentimentCounters() { for(int i=0;i<MAX_GAUGE_TYPE_SIZE;i++){ buy[i]=0;sell[i]=0;neutral[i]=0;} }
};

class CSymbolGauges
{
   public:
   string symbol_name;
   string urlparams;//params got the url
   CGauge *gauges[MAX_GAUGES];
   int num_indicators; //gauge types
   int num_moving_averages;
   
   CSentimentCounters sentiment[TIME_FRAME_SIZE];
   
   //sentiments
   string sentiment_summary_ma[TIME_FRAME_SIZE];
   string sentiment_summary_indicators[TIME_FRAME_SIZE];
   string sentiment_summary[TIME_FRAME_SIZE];
   
   
   
   CSymbolGauges(){symbol_name = NULL;}
   ~CSymbolGauges(){ num_indicators=0; num_moving_averages=0;  for (int i=0;i<MAX_GAUGES;i++)delete gauges[i]; urlparams=""; }
   
   void Initialize(SYMBOL_PAIR symbol_pair);
   void Calculate();
   void AnalyzeReadings();
   void ResetSentimentCounters();
   void SetSentimentCounters(GAUGE_RESULT result,TIME_FRAME time_frame,int gauge);
   void SetSummarySentiments(TIME_FRAME time_frame,string time_str);
   void CountIndicatorTypes();
   void SetURLCounters(TIME_FRAME time_frame,string time_str);
   void CalculateSummary(TIME_FRAME time_frame,string time_str);
   void AddToUrlParam(string value) {urlparams += symbol_name +"_" + value;}

};

CSymbolGauges::CountIndicatorTypes(void)
{
   GAUGE_TYPE type;
   for(int gauge=0;gauge<MAX_GAUGES;gauge++)
   {
      type = gauges[gauge].GetType();
      if(type == INDICATOR)
      {
         num_indicators++;
      }
      else if(type == MOVING_AVERAGE)
      {
         num_moving_averages++;
      }
   }
}

void CSymbolGauges::ResetSentimentCounters()
{
   
   for(int time_frame=0;time_frame<TIME_FRAME_SIZE;time_frame++)
   {
      sentiment[time_frame].buy[INDICATOR] = 0;;
      sentiment[time_frame].sell[INDICATOR] = 0;
      sentiment[time_frame].neutral[INDICATOR] = 0;
   
      sentiment[time_frame].buy[MOVING_AVERAGE] = 0;;
      sentiment[time_frame].sell[MOVING_AVERAGE] = 0;
      sentiment[time_frame].neutral[MOVING_AVERAGE] = 0;
   }
   
   
}

void CSymbolGauges::SetSentimentCounters(GAUGE_RESULT result, TIME_FRAME time_frame,int gauge)
{
   
   GAUGE_TYPE type = gauges[gauge].GetType();
   if(result == BUY)
   {
      sentiment[time_frame].buy[type]++;

   }
   else if(result == SELL)
   {
      sentiment[time_frame].sell[type]++;

   }
   else if(result== NEUTRAL)
   {
      sentiment[time_frame].neutral[type]++;
    
   }
}


void CSymbolGauges::SetURLCounters(TIME_FRAME time_frame,string time_str)
{
    AddToUrlParam(time_str + "_"+"NumBuyIndicator="+IntegerToString(sentiment[time_frame].buy[INDICATOR])+"&");
    AddToUrlParam(time_str + "_"+"NumSellIndicator="+IntegerToString(sentiment[time_frame].sell[INDICATOR])+"&");
    AddToUrlParam(time_str + "_"+"NumNeutralIndicator="+IntegerToString(sentiment[time_frame].neutral[INDICATOR])+"&");
    
    AddToUrlParam(time_str + "_"+"NumBuyMa="+IntegerToString(sentiment[time_frame].buy[MOVING_AVERAGE])+"&");
    AddToUrlParam(time_str + "_"+"NumSellMa="+IntegerToString(sentiment[time_frame].sell[MOVING_AVERAGE])+"&");
    AddToUrlParam(time_str + "_"+"NumNeutralMa="+IntegerToString(sentiment[time_frame].neutral[MOVING_AVERAGE])+"&");
 
}

void CSymbolGauges::CalculateSummary(TIME_FRAME time_frame,string time_str)
{
   SUMMARY_STATUS summary_indicator = 0;
   SUMMARY_STATUS summary_movingaverage = 0;
   SUMMARY_STATUS summary_overall = 0; //overall summmary
   
   int indicator_delta = sentiment[time_frame].buy[INDICATOR] - sentiment[time_frame].sell[INDICATOR];
   string summary = ""; 
    //indicators
    if(indicator_delta == 0)
    {
      summary_indicator = SUMMARY_NEUTRAL;
    }
    else if (indicator_delta >0)//is buy
    {
      if(indicator_delta>3)
      {
         summary_indicator = SUMMARY_STRONG_BUY;
      }
      else
      {
         summary_indicator = SUMMARY_BUY;  
      }
    }
    else
    {
      if(indicator_delta<-3)
      {
         summary_indicator = SUMMARY_STRONG_SELL;
      }
      else
      {
         summary_indicator = SUMMARY_SELL;  
      }
    }
    
    summary = MapSummaryStatusString(summary_indicator);
    AddToUrlParam(time_str + "_SummaryIndicator="+summary+"&");
    
    
    //ma
    //1:11 strong buy/sell
    //2:10 buy/sell
   int ma_delta = sentiment[time_frame].buy[MOVING_AVERAGE] - sentiment[time_frame].sell[MOVING_AVERAGE];
   
   if(ma_delta == 0)
   {
      summary_movingaverage = SUMMARY_NEUTRAL;
   }
   else if(ma_delta>0)//is buy
   {
      if(sentiment[time_frame].buy[MOVING_AVERAGE]>10)
      {
         summary_movingaverage = SUMMARY_STRONG_BUY;
      }
      else
      {
         summary_movingaverage = SUMMARY_BUY;
      }
   } 
   else
   {
      if(sentiment[time_frame].sell[MOVING_AVERAGE]>10)
      {
         summary_movingaverage = SUMMARY_STRONG_SELL;
      }
      else
      {
         summary_movingaverage = SUMMARY_SELL;
      }
      
   }
   
   summary = MapSummaryStatusString(summary_movingaverage);
   AddToUrlParam(time_str + "_SummaryMovingAverage="+summary+"&"); 
   
   //overall summary
   if(summary_movingaverage == summary_indicator)
   {
      summary_overall = summary_movingaverage; 
   }
   else if( ((summary_movingaverage==SUMMARY_STRONG_BUY) && (summary_indicator == SUMMARY_BUY)) 
          || ((summary_movingaverage==SUMMARY_BUY) && ( summary_indicator == SUMMARY_STRONG_BUY)))
   {
      summary_overall = SUMMARY_STRONG_BUY;
   }
   else if( ((summary_movingaverage==SUMMARY_STRONG_SELL) && (summary_indicator == SUMMARY_SELL)) 
          || ((summary_movingaverage==SUMMARY_SELL) && ( summary_indicator == SUMMARY_STRONG_SELL)))
   {
      summary_overall = SUMMARY_STRONG_SELL;
   }
   else if( ((summary_movingaverage==SUMMARY_STRONG_SELL) && (summary_indicator == SUMMARY_STRONG_BUY)) 
          || ((summary_movingaverage==SUMMARY_STRONG_BUY)  && (summary_indicator == SUMMARY_STRONG_SELL)))
   {
      summary_overall = SUMMARY_NEUTRAL;
   }
   else if( ((summary_movingaverage==SUMMARY_SELL) && (summary_indicator == SUMMARY_BUY)) 
          || ((summary_movingaverage==SUMMARY_BUY)  && (summary_indicator == SUMMARY_SELL)))
   {
      summary_overall = SUMMARY_NEUTRAL;
   }  
   else if( ((summary_movingaverage==SUMMARY_SELL) && (summary_indicator == SUMMARY_NEUTRAL)) 
          || ((summary_movingaverage==SUMMARY_BUY)  && (summary_indicator == SUMMARY_NEUTRAL)))
   {
      summary_overall = SUMMARY_NEUTRAL;
   }
   else if( ((summary_movingaverage==SUMMARY_NEUTRAL) && (summary_indicator == SUMMARY_BUY)) 
          || ((summary_movingaverage==SUMMARY_NEUTRAL)  && (summary_indicator == SUMMARY_SELL)))
   {
      summary_overall = SUMMARY_NEUTRAL;
   }
   else if( ((summary_movingaverage==SUMMARY_NEUTRAL) && (summary_indicator == SUMMARY_STRONG_BUY)) 
          || ((summary_movingaverage==SUMMARY_STRONG_BUY)  && (summary_indicator == SUMMARY_NEUTRAL)))
   {
      summary_overall = SUMMARY_BUY;
   }
   else if( ((summary_movingaverage==SUMMARY_NEUTRAL) && (summary_indicator == SUMMARY_STRONG_SELL)) 
          || ((summary_movingaverage==SUMMARY_STRONG_SELL)  && (summary_indicator == SUMMARY_NEUTRAL)))
   {
      summary_overall = SUMMARY_SELL;
   }
   else
   {
      summary_overall = SUMMARY_NEUTRAL;
   }

    
   summary = MapSummaryStatusString(summary_overall);
   AddToUrlParam(time_str + "_SummaryOverall="+summary+"&"); 
    
}

void CSymbolGauges::SetSummarySentiments(TIME_FRAME time_frame,string time_str)
{
    
    string sentiment_String = "";
    int sentiment_flag = 0;
    int indicator_delta = 0;
    SUMMARY_STATUS summary_indicator = 0;
     
    SetURLCounters(time_frame,time_str);
    CalculateSummary(time_frame,time_str);
     
     
     
     
       
    //indicator delta <=3 sell/buy. >3 strong buy/sell. 0=neutral
    //averages 11:1 strong buy/sell 10:2 buy/sell
    //calulate overall summary
    
    
    
    
    
    
    
    /*
    sentiment_flag = sentiment[time_frame].buy[INDICATOR] - sentiment[time_frame].sell[INDICATOR];
    
    if(sentiment_flag >=-1 && sentiment_flag <=1)
    {
      urlparams +=time_str +"_"+"SummaryIndicator=Neutral&";
    }
    if(sentiment_flag>)
      */
    
    
}

void CSymbolGauges::AnalyzeReadings(void)
{
   string time = "";
   string name = "";
   string gauge_sentiment = "";
   string gauge_value = "";
   GAUGE_RESULT result;
   urlparams = "";
   
   ResetSentimentCounters();
   
   for(int time_frame=0;time_frame<TIME_FRAME_SIZE;time_frame++)
   {
      time = MapTimeFrameString((TIME_FRAME)time_frame);
         
      for(int gauge=0;gauge<MAX_GAUGES;gauge++)
      {
         name = gauges[gauge].GetName();
         result = gauges[gauge].GetSentiment((TIME_FRAME)time_frame);   
         SetSentimentCounters(result,(TIME_FRAME)time_frame,gauge);
         
        
         
         gauge_sentiment = MapGaugeResultString(result);
         gauge_value = gauges[gauge].GetValue((TIME_FRAME)time_frame);
         
         
         
         AddToUrlParam(time + "_" + name + "=" + gauge_sentiment + "&");
         AddToUrlParam(time + "_" + name + "_value=" + gauge_value + "&");
               
        
      }
      
       
      
      SetSummarySentiments((TIME_FRAME)time_frame,time);   
   }
      
  //Print("URL Params is " + urlparams);
   
}



void CSymbolGauges::Initialize(SYMBOL_PAIR symbol_pair)
{
   symbol_name = MapSymbolEnum(symbol_pair);
   if(ASSERT(symbol_name!=NULL,"Invalid Symbol Name") == FAILURE){return;}
   
   
   gauges[RSI] = new CGaugeRSI(symbol_name,14);
   gauges[RSI].GetHandle();
   
   gauges[STOCH] = new CGaugeStoch(symbol_name);
   gauges[STOCH].GetHandle();
   
   gauges[MA5] = new CGaugeMA5(symbol_name);
   gauges[MA5].GetHandle();
   
   gauges[MA10] = new CGaugeMA10(symbol_name);
   gauges[MA10].GetHandle();
   
   
   CountIndicatorTypes();
   
}
void CSymbolGauges::Calculate(void)
{
   for(int gauge=0;gauge<MAX_GAUGES;gauge++)
   {
      gauges[gauge].Calculate();
   }
}