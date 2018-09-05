from enum import Enum

class GaugeType(Enum):
    INDICATOR = 0
    MOVING_AVERAGE = 1
    
KEY_SYMBOLNAMES = "SymbolList"
KEY_TIMEFRAMES = "TimeFrameList"
KEY_INDICATOR_LIST = "IndicatorList"
KEY_MA_LIST = "MaList"
KEY_DELIMINATOR = "-" #string contains multiple values, this is the split 
KEY_SEPERATOR = "_"

KEY_SUMMARY_INDICATOR = "SummaryIndicator"
KEY_SUMMARY_MOVINGAVERAGE = "SummaryMovingAverage"
KEY_SUMMARY_OVERALL = "SummaryOverall"

KEY_NUM_BUY_INDICATOR = "NumBuyIndicator"
KEY_NUM_SELL_INDICATOR = "NumSellIndicator"
KEY_NUM_NEUTRAL_INDICATOR = "NumNeutralIndicator"
KEY_NUM_BUY_MOVINGAVERAGE = "NumBuyMa"
KEY_NUM_SELL_MOVINGAVERAGE = "NumSellMa"
KEY_NUM_NEUTRAL_MOVINGAVERAGE =  "NumNeutralMa"

KEY_GAUGE_VALUE = "value"


class HTMLGenerator:
    symbols = {}

    @staticmethod
    def Set(__symbols):
        HTMLGenerator.symbols = __symbols

    @staticmethod
    def GetFirstKey():
        if(bool(HTMLGenerator.symbols) == True):
            for key in HTMLGenerator.symbols:
                return key
        else:
            return None
    @staticmethod
    def GetTextClass(value):
        
        if(value == "Neutral"):
            return "neutral_text"
        if(value == "Buy" or value=="Strong Buy"):
            return "buy_text"
        
        return "sell_text"
        

    @staticmethod
    def GetTableIndicatorHead(pair,time_frame):
        
        if(bool(HTMLGenerator.symbols) == False):
            return ""
        
        html = ("<table class='table_summary' id='detail_table'>"
                "<thead>"
                "<tr class='bottom-thick'>"
                "<th>Name</th>"
                "<th>Value</th>"
                "<th>Action</th>"
                "</tr></thead>")
        return html

    @staticmethod
    def GetTableIndicatorBody(pair,time_frame):
        
        if(bool(HTMLGenerator.symbols) == False):
            return ""

        html = ""
        for indicator in HTMLGenerator.symbols[pair].time_frames[time_frame].Indicators:
            html+= "<tr>"
            html+="<td class='"+ time_frame+"'>"+HTMLGenerator.symbols[pair].time_frames[time_frame].Indicators[indicator].name+"</td>"
            html+="<td class='"+ time_frame+"'>"+HTMLGenerator.symbols[pair].time_frames[time_frame].Indicators[indicator].value+"</td>"
            html+="<td class='"+ time_frame+"'>"+HTMLGenerator.symbols[pair].time_frames[time_frame].Indicators[indicator].action+"</td>"
            html+="</tr>"
        html += "</table>"
        return html
    
    @staticmethod
    def GetSummaryTableBody():
        
        
        if(bool(HTMLGenerator.symbols) == False):
            return ""

        html = ""

        #symbol pairs
        for pair in HTMLGenerator.symbols:
            html+= ("<tr><th class='all-around' scope='row' rowspan = '4' >" + pair + "</th></tr>")
            
            #moving averages
            html+="<tr>"
            html+="<td> Moving Averages </td>"
            for time_frame in HTMLGenerator.symbols[pair].time_frames:
                html+="<td class='"+ time_frame+"'>"+ HTMLGenerator.symbols[pair].time_frames[time_frame].MovingAveragesSummary  +"</td>"
            html+="</tr>"

            #indicators
            html+="<tr>"
            html+="<td>Indicators</td>"
            for time_frame in HTMLGenerator.symbols[pair].time_frames:
                html+="<td class='"+ time_frame+"'>"+ HTMLGenerator.symbols[pair].time_frames[time_frame].IndicatorsSummary  +"</td>"
            html+="</tr>"

            html+="<tr>"
            html+="<td class='bold_text'>Summary</td>"
            for time_frame in HTMLGenerator.symbols[pair].time_frames:
                summary = HTMLGenerator.symbols[pair].time_frames[time_frame].OverallSummary
                html+="<td class='"+ time_frame+" "+ HTMLGenerator.GetTextClass(summary) +"'>"+ summary  +"</td>"
            html+="</tr>"

        html+="</table>"     
        return html
      

    @staticmethod
    def GetSummaryTableHeader():
        html =("<table  class='table_summary' id='summary_table'>"
            "<thead>"
            "<tr class='bottom-thick'>"
            "<th>Name</th>"
            "<th>Type</th>")

        pair = HTMLGenerator.GetFirstKey()
        if(pair == None):
            return "<BR>No Server Values Sent<BR>"

       
        for time_frame in HTMLGenerator.symbols[pair].time_frames:
            html +="<td class='"+ time_frame+"'>"+ time_frame + "</th>"

        html += "</tr></thead>"

      
        return html



class Symbols:
    def __init__(self):
        
        self.symbol_list = {}
        self.html = ""
        self.param_base =""

    def SanatizeParams(self,urlparams):
        for key in urlparams:
            urlparams[key] = urlparams[key].strip('\n')

    def ReadGauges(self,urlparams,symbol_detail):
        
        indicator_list = urlparams[KEY_INDICATOR_LIST]
        indicator_names = indicator_list.split(KEY_DELIMINATOR)

        for name in indicator_names:
            gd = GaugeDetail()
            gd.name = name
            gd.value = urlparams[self.param_base+name+KEY_SEPERATOR+KEY_GAUGE_VALUE]
            gd.action = urlparams[self.param_base+name]
            
            symbol_detail.Indicators[name] = gd
               
        ma_list = urlparams[KEY_MA_LIST]
        ma_names = ma_list.split(KEY_DELIMINATOR)
        for ma in ma_names:
            gd = GaugeDetail()
            gd.name = ma
            gd.value = urlparams[self.param_base+ma+KEY_SEPERATOR+KEY_GAUGE_VALUE]
            gd.action = urlparams[self.param_base+ma]
            symbol_detail.MovingAverages[ma] = gd
            

    def ReadSymbol(self,urlparams,time_frame,symbol_name):

        symbol_detail = SymbolDetail()
        self.param_base = symbol_name + KEY_SEPERATOR+time_frame+KEY_SEPERATOR

        #read the overal summary
        symbol_detail.IndicatorsSummary = urlparams[self.param_base+KEY_SUMMARY_INDICATOR]
        symbol_detail.MovingAveragesSummary = urlparams[self.param_base+KEY_SUMMARY_MOVINGAVERAGE]
        symbol_detail.OverallSummary = urlparams[self.param_base+KEY_SUMMARY_OVERALL]

        #read gauge numbers summeries
        symbol_detail.IndicatorGaugeSummary.num_buy = urlparams[self.param_base+KEY_NUM_BUY_INDICATOR]
        symbol_detail.IndicatorGaugeSummary.num_sell = urlparams[self.param_base+KEY_NUM_SELL_INDICATOR]
        symbol_detail.IndicatorGaugeSummary.num_neutral = urlparams[self.param_base+KEY_NUM_NEUTRAL_INDICATOR]

        symbol_detail.MovingAveragesGaugeSummary.num_buy = urlparams[self.param_base+KEY_NUM_BUY_MOVINGAVERAGE]
        symbol_detail.MovingAveragesGaugeSummary.num_sell = urlparams[self.param_base+KEY_NUM_SELL_MOVINGAVERAGE]
        symbol_detail.MovingAveragesGaugeSummary.num_neutral = urlparams[self.param_base+KEY_NUM_NEUTRAL_MOVINGAVERAGE]

        self.ReadGauges(urlparams,symbol_detail)

        return symbol_detail

    def Read(self,urlparams):

        self.SanatizeParams(urlparams) 

        names = urlparams[KEY_SYMBOLNAMES]
        frames = urlparams[KEY_TIMEFRAMES]

        symbol_names = names.split(KEY_DELIMINATOR)
        time_frames  = frames.split(KEY_DELIMINATOR)

        for s in symbol_names:
            syb = Symbol()
            syb.name = s
            
            for t in time_frames:
                syb.time_frames[t] = self.ReadSymbol(urlparams,t,s) 

            self.symbol_list[syb.name] = syb 

        #test_time = "M15"
        #pair = "GBPUSD"
        #print(pair+":"+test_time)
        #print("Indicator " + self.symbol_list[pair].time_frames[test_time].IndicatorSummary)
        #print("Moving average " + self.symbol_list[pair].time_frames[test_time].MovingAveragesSummary)
        #print("Overall " + self.symbol_list[pair].time_frames[test_time].OverallSummary)

        #print("num buy indicator " + self.symbol_list[pair].time_frames[test_time].IndicatorGaugeSummary.num_buy)
        #print("num sell indicator " + self.symbol_list[pair].time_frames[test_time].IndicatorGaugeSummary.num_sell)
        #print("num neutral indicator " + self.symbol_list[pair].time_frames[test_time].IndicatorGaugeSummary.num_neutral)

        #print("num buy ma " + self.symbol_list[pair].time_frames[test_time].MovingAveragesGaugeSummary.num_buy)
        #print("num sell ma " + self.symbol_list[pair].time_frames[test_time].MovingAveragesGaugeSummary.num_sell)
        #print("num neutral ma " + self.symbol_list[pair].time_frames[test_time].MovingAveragesGaugeSummary.num_neutral)

        #indicator_name = "RSI"
        #print("indicator name " + self.symbol_list[pair].time_frames[test_time].Indicators[indicator_name].name)
        #print("indicator value " + self.symbol_list[pair].time_frames[test_time].Indicators[indicator_name].value)
        #print("indicator action " + self.symbol_list[pair].time_frames[test_time].Indicators[indicator_name].action)

        #ma_name = "MA10"
        #print("ma name " + self.symbol_list[pair].time_frames[test_time].MovingAverages[ma_name].name)
        #print("ma value " + self.symbol_list[pair].time_frames[test_time].MovingAverages[ma_name].value)
        #print("ma action " + self.symbol_list[pair].time_frames[test_time].MovingAverages[ma_name].action)

        for key in urlparams:
            self.html = self.html + key + ":" + urlparams[key] + '<br>'
         
class Symbol:
    def __init__(self):
        self.name = ""#symbol name
        self.time_frames = {}  #summeries per time frame 


class SymbolDetail:
    def __init__(self):
        self.MovingAveragesSummary = ""
        self.IndicatorsSummary = ""
        self.OverallSummary=""
        
        self.IndicatorGaugeSummary = GaugeSummary()#number summaries
        self.MovingAveragesGaugeSummary = GaugeSummary()
        
        self.Indicators={}#gauge details
        self.MovingAverages={}



class GaugeDetail:
    def __init__(self):
        self.name =""
        self.value=""
        self.action=""
        self.type=0

class GaugeSummary:
    def __init__(self):
        self.num_buy = 0
        self.num_sell = 0
        self.num_neutral = 0


if __name__ == '__main__':
    d = {}
    with open("request.txt") as f:
        for line in f:
            (key, val) = line.split(":")
            d[key] = val
    
    symb = Symbols()
    symb.Read(d)
     