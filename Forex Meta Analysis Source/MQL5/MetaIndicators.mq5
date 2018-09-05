//+------------------------------------------------------------------+
//|                                               socket_library.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <SymbolGauges.mqh>

class CMetaIndicator
{
  
   
   CSymbolGauges symbol_pairs[SYMBOL_SIZE];
   string SymbolList;
   string IndicatorList;
   string MaList;
   string TimeFrameList;
   
   public:
   
   
   void Initialize();
   void Calculate();
   void AnalyzeReadings();
   string GetUrlParams();
   void SetLists();
   string GetSymbolList() {return SymbolList;}
   string GetIndicatorList() {return IndicatorList;}
   string GetMaList() {return MaList;}
   string GetLists() { return SymbolList + IndicatorList + MaList + TimeFrameList; }// + MaList } <--ADD ME
  
   
};

void CMetaIndicator::SetLists(void)
{
   SymbolList = "SymbolList=";
   TimeFrameList = "TimeFrameList=";
   IndicatorList = ""; //set in if statements
   MaList = "";
   
   
   for(int symbol=0;symbol<SYMBOL_SIZE;symbol++)
   {
      SymbolList+=MapSymbolEnum((SYMBOL_PAIR)symbol);
      
      if(symbol+1 != SYMBOL_SIZE)
      {
         SymbolList +="-";
      }
   }
   SymbolList += "&";
      
   for(int gauge=0;gauge<MAX_GAUGES;gauge++)
   {
   
      if(symbol_pairs[0].gauges[gauge].GetType() == INDICATOR)
      {
         if(IndicatorList == "")//check for empty indicator list. no need to append '-'
         {
            IndicatorList+="IndicatorList="+symbol_pairs[0].gauges[gauge].GetName();//MapIndicatorString((GAUGES_INDICATORS)gauge);
         }
         else
         {
            IndicatorList+="-"+symbol_pairs[0].gauges[gauge].GetName();
         }
        
      }
      else
      {
         if(MaList == "")
         {
            MaList+="MaList="+symbol_pairs[0].gauges[gauge].GetName();
         }
         else
         {
            MaList+="-"+symbol_pairs[0].gauges[gauge].GetName();
         }
      }
      

   }
   IndicatorList += "&";
   MaList += "&";
   
 
   for(int tf=0;tf<TIME_FRAME_SIZE;tf++)
   {
      TimeFrameList+=MapTimeFrameString((TIME_FRAME)tf); // ((GAUGES_MAS)ma);
      
      if(tf+1 != TIME_FRAME_SIZE)
      {
         TimeFrameList +="-";
      }
   }
   TimeFrameList += "&";
   
   
  Print("Symbol List is " + SymbolList);
  Print("Indicator List is " + IndicatorList);
  Print("Ma List is " + MaList);
  Print("TimeFrame is " + TimeFrameList); 
   
}

CMetaIndicator::Initialize(void)
{
  for(int pair=0;pair<SYMBOL_SIZE;pair++)
  {
   symbol_pairs[pair].Initialize((SYMBOL_PAIR)pair);
  }
  
  SetLists();
  
}

CMetaIndicator::Calculate(void)
{
  for(int pair=0;pair<SYMBOL_SIZE;pair++)
  {
      symbol_pairs[pair].Calculate();
  }
}

CMetaIndicator::AnalyzeReadings(void)
{
  for(int pair=0;pair<SYMBOL_SIZE;pair++)
  {
   symbol_pairs[pair].AnalyzeReadings();
  }
   //symbol_pairs[GBPUSD].AnalyzeReadings();
}

string CMetaIndicator::GetUrlParams(void)
{
   string params = "";
   for(int pair=0;pair<SYMBOL_SIZE;pair++)
   {
      params+=symbol_pairs[pair].urlparams;
   }
   return params;
}
CMetaIndicator mi;


void SendToServerOnTimer()
{
     
      
      int SecondsBeforeNextSend = 1;
      static int last_send = 0;
 
      int curr_seconds = ((int)TimeCurrent() % 60);


      SendToServer(mi.GetLists()+ mi.GetUrlParams());
      last_send = curr_seconds;
      
      
}

void SendToServer(string url_params)
{
   string headers = "Content-Type: application/x-www-form-urlencoded";
   char post[], result[];
   string str="";

   int data_len = StringLen(url_params);
   
   
   StringToCharArray(url_params, post,0,data_len); // Must specify string length; otherwise array has terminating null character in it
   int res=WebRequest("POST","http://127.0.0.1/data ",headers,0,post,result,str);
   Print("Status code: " , res, ", error: ", GetLastError());
   //Print("Server response: ", CharArrayToString(result));
}

int OnInit()
  {
//---
   
   mi.Initialize();

   Print("Init is done");

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  

   mi.Calculate();
   mi.AnalyzeReadings();
   SendToServerOnTimer();
 
   

  }
//+------------------------------------------------------------------+
