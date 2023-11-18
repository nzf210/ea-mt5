input int FastMAPeriod = 5;
input int SlowMAPeriod = 10;
input double Lots = 0.01;
input double StopLoss = 30;
input double TakeProfit = 50;
input int TrailingStart = 5; // Trailing Start distance in pips
input int TrailingStop = 10; // Trailing Stop distance in pips

void OnTick() {
   double fastMA = iMA(_Symbol, 0, FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
   double slowMA = iMA(_Symbol, 0, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);

   // Check for open positions
   double openPrice, stopLossPrice, takeProfitPrice;
   ulong ticket;

   if (fastMA > slowMA) {
       // Uptrend, open buy position
       openPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
       stopLossPrice = openPrice - StopLoss * _Point;
       takeProfitPrice = openPrice + TakeProfit * _Point;
   
       ticket = OrderSend(_Symbol, OP_BUY, Lots, openPrice, 3, stopLossPrice, takeProfitPrice, "Buy Order", 0, 0, clrGreen);
   } else if (fastMA < slowMA) {
       // Downtrend, open sell position
       openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
       stopLossPrice = openPrice + StopLoss * _Point;
       takeProfitPrice = openPrice - TakeProfit * _Point;
   
       ticket = OrderSend(_Symbol, OP_SELL, Lots, openPrice, 3, stopLossPrice, takeProfitPrice, "Sell Order", 0, 0, clrRed);
   }
   
   if (ticket > 0) {
       string orderType = (fastMA > slowMA) ? "Buy" : "Sell";
       Print(orderType, " Order Placed. Ticket:", ticket);
   
       // Set Trailing Start
       double trailingStartValue = (fastMA > slowMA) ? openPrice + TrailingStart * _Point : openPrice - TrailingStart * _Point;
       ulong trailingStartTicket = OrderSend(_Symbol, (fastMA > slowMA) ? OP_BUY : OP_SELL, Lots, openPrice, 3, trailingStartValue, takeProfitPrice, orderType + " Order Trailing Start", 0, 0, (fastMA > slowMA) ? clrGreen : clrRed);
   
       if (trailingStartTicket > 0) {
           Print(orderType, " Order Trailing Start Placed");
       } else {
           Print("Error placing ", orderType, " Order Trailing Start. Error:", GetLastError());
       }
   
       // Set Trailing Stop
       double trailingStopValue = (fastMA > slowMA) ? openPrice - TrailingStop * _Point : openPrice + TrailingStop * _Point;
       if (OrderModify(ticket, openPrice, trailingStopValue, takeProfitPrice, 0, (fastMA > slowMA) ? clrGreen : clrRed)) {
           Print(orderType, " Order Trailing Stop Modified");
       } else {
           Print("Error modifying ", orderType, " Order Trailing Stop. Error:", GetLastError());
       }
   }

}
