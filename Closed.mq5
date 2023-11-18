//+------------------------------------------------------------------+
//|                                                       Closed.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
    int totalPositions = PositionsTotal(); // Get the total number of open positions

    if(totalPositions > 0)
    {
        for(int i = 0; i < totalPositions; i++)
        {
            ulong ticket = PositionGetTicket(i); // Get the ticket number of each position
            bool result = PositionClose(ticket); // Close the position by ticket number

            if(result)
            {
                Print("Closed position with ticket:", ticket);
            }
            else
            {
                Print("Failed to close position with ticket:", ticket);
                Print("Error code:", GetLastError());
            }
        }
    }
    else
    {
        Print("No open positions to close.");
    }
  }
//+------------------------------------------------------------------+
