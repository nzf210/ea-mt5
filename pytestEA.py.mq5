//+------------------------------------------------------------------+
//|                                                  pytestEA.py.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Megasupiori Kab."
#property link      "https://www.mql5.com"
#property strict

#include <Comment.mqh>
//---
#define EXPERT_NAME     "=== Uji Coba EA Rebate: "
#define EXPERT_VERSION  "1.0.1"
//--- custom colors
#define COLOR_BACK      clrBlack
#define COLOR_BORDER    clrDimGray
#define COLOR_CAPTION   clrDodgerBlue
#define COLOR_TEXT      clrLightGray
#define COLOR_WIN       clrLimeGreen
#define COLOR_LOSS      clrOrangeRed
//--- input parameters
input bool              InpAutoColors=true;//Auto Colors
input string            title_ea_options="=== Pilihan Options ===";
input ENUM_TIMEFRAMES   InpTimeframe=PERIOD_D1;//Timeframe
input double            InpVolume=0.1;//Lots
// input uint              InpStopLoss=20;//Stop Loss, pips
// input uint              InpTakeProfit=15;//Take Profit, pips
//--- global variables
CComment comment;
int tester;
int visual_mode;

//# Variable sendiri
//+------------------------------------------------------------------+
input int FastMAPeriod  = 5;
input int SlowMAPeriod  = 10;
input double Lots       = 0.01;
input double StopLoss   = 30;
input double TakeProfit = 5;
input int TrailingStart = 5; // Trailing Start distance in pips
input int TrailingStop  = 10; // Trailing Stop distance in pips
double openPrice, stopLossPrice, takeProfitPrice;
ulong ticket;

// # Tambahan
#define EXPERT_MAGIC 123456
MqlTradeRequest request={};
MqlTradeResult  result={};      
int jmlTrxTerbuka = 1;
bool adaOpenTrx = false;
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//| Fungsi ini merupakan bagian dari EA yang dipanggil saat          |
//| EA dijalankan. Pada bagian ini, sebuah timer dengan interval 60  |
//| detik (1 menit) dibuat menggunakan fungsi EventSetTimer(60).     |
//| Fungsi ini mengembalikan nilai INIT_SUCCEEDED jika inisialisasi  | 
//| berhasil.                                                        |
//+------------------------------------------------------------------+
int OnInit()
   {
   tester=MQLInfoInteger(MQL_TESTER);
   visual_mode=MQLInfoInteger(MQL_VISUAL_MODE);
//--- panel position
   int y=30;
   if(ChartGetInteger(0,CHART_SHOW_ONE_CLICK))
      y=120;
//--- panel name
   srand(GetTickCount());
   string name="panel_"+IntegerToString(rand());
   comment.Create(name,20,y);
//--- panel style
   comment.SetAutoColors(InpAutoColors);
   comment.SetColor(COLOR_BORDER,COLOR_BACK,255);
   comment.SetFont("Lucida Console",13,false,1.7);
//---
#ifdef __MQL5__
   comment.SetGraphMode(!tester);
#endif
//--- not updated strings
   comment.SetText(0,StringFormat("Expert: %s v.%s",EXPERT_NAME,EXPERT_VERSION),COLOR_CAPTION);
   comment.SetText(1,"Timeframe: "+StringSubstr(EnumToString(InpTimeframe),7),COLOR_TEXT);
   comment.SetText(2,StringFormat("Volume: %.2f",InpVolume),COLOR_TEXT);
   comment.SetText(3,StringFormat("Stop Loss: %d pips",StopLoss),COLOR_LOSS);
   comment.SetText(4,StringFormat("Take Profit: %d pips",TakeProfit),COLOR_WIN);
   comment.SetText(5,"Time: "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS),COLOR_TEXT);
   comment.SetText(6,"Price: "+DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits),COLOR_TEXT);
   comment.SetText(7,"PAIR : "+_Symbol,COLOR_TEXT);
   comment.Show();
//--- run timer
   if(!tester)
      EventSetTimer(1);
   OnTimer();
//--- done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//| Fungsi ini dipanggil saat EA dihentikan atau di-deinitialize     |
//| Pada bagian ini, timer yang telah dibuat sebelumnya dihentikan   |
//| dengan                                                           | 
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {
      EventKillTimer();
   }
//+------------------------------------------------------------------+
//| Expert tick function                                             |                                 
//| Fungsi ini dipanggil pada setiap perubahan tick (perubahan harga)| 
//| Saat ini, fungsi ini kosong dan belum diimplementasikan          |
//+------------------------------------------------------------------+
void OnTick()
{
    double fastMA = iMA(_Symbol, PERIOD_CURRENT, FastMAPeriod, 13, MODE_SMA, PRICE_CLOSE);
    double slowMA = iMA(_Symbol, PERIOD_CURRENT, SlowMAPeriod, 20, MODE_SMA, PRICE_CLOSE);

    int jmlTrxTerbuka = PositionsTotal();

    // Check if there are open positions before opening new ones
    if (jmlTrxTerbuka < 3) {
        if (fastMA > slowMA) {
            openPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            stopLossPrice = openPrice - StopLoss * _Point;
            takeProfitPrice = openPrice + TakeProfit * _Point;
            request.action = TRADE_ACTION_DEAL;
            request.symbol = _Symbol;
            request.volume = 0.1;
            request.type = ORDER_TYPE_BUY;
            request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            request.deviation = 5;
            request.magic = EXPERT_MAGIC;
            request.tp = takeProfitPrice;
            request.sl = stopLossPrice;
        } else if (fastMA < slowMA) {
            openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            stopLossPrice = openPrice + StopLoss * _Point;
            takeProfitPrice = openPrice - TakeProfit * _Point;
            request.action = TRADE_ACTION_DEAL;
            request.symbol = _Symbol;
            request.volume = 0.1;
            request.type = ORDER_TYPE_SELL;
            request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            request.deviation = 5;
            request.magic = EXPERT_MAGIC;
            request.tp = takeProfitPrice;
            request.sl = stopLossPrice;
        }

        // Open positions based on conditions
        if (jmlTrxTerbuka == 0 || jmlTrxTerbuka == 1) {
            ticket = OrderSend(request, result);
        } else if (jmlTrxTerbuka == 2) {
            // Close all positions if profit > 0
            double totalProfit = 0.0;
            for (int i = 0; i < jmlTrxTerbuka; i++) {
                ulong ticket = PositionGetTicket(i);
                totalProfit += PositionGetDouble(POSITION_PROFIT, ticket);
            }
            
            if (totalProfit > 0) {
                for (int i = 0; i < jmlTrxTerbuka; i++) {
                    ulong ticket = PositionGetTicket(i);
                    PositionClose(ticket);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//| Fungsi ini akan dipanggil setiap kali timer yang telah dibuat di |
//| OnInit() mencapai waktu yang telah ditetapkan (60 detik). Fungsi |
//| ini juga kosong dan belum diimplementasikan.                     |
//+------------------------------------------------------------------+
void OnTimer()
   {
   
   
   }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//| Fungsi ini akan dipanggil saat ada perubahan dalam aktivitas     |
//| trading, seperti pembukaan atau penutupan posisi. Seperti fungsi |
//| lainnya, pada kode saat ini, fungsi ini kosong dan belum         |
//| diimplementasikan.                                               |
//+------------------------------------------------------------------+
void OnTrade()
   {
   
   
   
   }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//| Fungsi ini dipanggil setiap kali terjadi transaksi trading.      |
//| Parameter yang dilewatkan berisi informasi terkait transaksi yang|
//| terjadi.                                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
   {
   
   
   }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//| Fungsi ini akan dipanggil saat ada peristiwa tertentu yang       |
//| terjadi pada chart, seperti klik mouse atau perubahan tampilan.  |
//| Informasi peristiwa tersebut disampaikan melalui                 |
//| parameter-parameter yang diberikan.                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
   {
      int res=comment.OnChartEvent(id,lparam,dparam,sparam);
      //--- move panel event
         if(res==EVENT_MOVE)
            return;
      //--- change background color
         if(res==EVENT_CHANGE)
            comment.Show();
   }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//| Fungsi ini akan dipanggil saat ada perubahan dalam order         |
//| book (buku pesanan) untuk simbol (pasangan mata uang) tertentu   |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
   {
   
   }

//+==================================================================+
void ShowTextOnChart(string text, int x_coord, int y_coord, int font_size = 10, color text_color = clrBlack) {
    // Create a text label object
    int text_label = ObjectCreate(0, "text_label", OBJ_LABEL, 0, 0, 0);
    
    // Set the text label parameters
    ObjectSetString(0, "text_label", OBJPROP_TEXT, text);
    ObjectSetInteger(0, "text_label", OBJPROP_XDISTANCE, x_coord);
    ObjectSetInteger(0, "text_label", OBJPROP_YDISTANCE, y_coord);
    ObjectSetInteger(0, "text_label", OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(0, "text_label", OBJPROP_COLOR, text_color);
}
//+==================================================================+