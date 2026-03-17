#ifndef __XAU_TRADEJOURNAL_MQH__
#define __XAU_TRADEJOURNAL_MQH__

string OrderTypeToText(int orderType)
{
   if(orderType == OP_BUY) return "BUY";
   if(orderType == OP_SELL) return "SELL";
   if(orderType == OP_BUYLIMIT) return "BUYLIMIT";
   if(orderType == OP_SELLLIMIT) return "SELLLIMIT";
   if(orderType == OP_BUYSTOP) return "BUYSTOP";
   if(orderType == OP_SELLSTOP) return "SELLSTOP";
   return "UNKNOWN";
}

void EnsureTradeJournalHeader()
{
   if(!EnableCSVLogging)
      return;

   int handle = FileOpen(CSVFileName, FILE_CSV | FILE_READ | FILE_WRITE, ',');
   if(handle < 0)
   {
      LogError("Failed to open CSV journal");
      return;
   }

   if(FileSize(handle) == 0)
   {
      FileWrite(
         handle,
         "close_time",
         "symbol",
         "ticket",
         "type",
         "lots",
         "open_price",
         "close_price",
         "stop_loss",
         "take_profit",
         "profit",
         "swap",
         "commission",
         "net_profit",
         "magic_number",
         "comment"
      );
   }

   FileClose(handle);
}

void AppendClosedTradeToCSV()
{
   if(!EnableCSVLogging)
      return;

   int handle = FileOpen(CSVFileName, FILE_CSV | FILE_READ | FILE_WRITE, ',');
   if(handle < 0)
   {
      LogError("Failed to open CSV journal for append");
      return;
   }

   FileSeek(handle, 0, SEEK_END);

   double netProfit = OrderProfit() + OrderSwap() + OrderCommission();

   FileWrite(
      handle,
      TimeToString(OrderCloseTime(), TIME_DATE | TIME_SECONDS),
      OrderSymbol(),
      IntegerToString(OrderTicket()),
      OrderTypeToText(OrderType()),
      DoubleToString(OrderLots(), 2),
      DoubleToString(OrderOpenPrice(), Digits),
      DoubleToString(OrderClosePrice(), Digits),
      DoubleToString(OrderStopLoss(), Digits),
      DoubleToString(OrderTakeProfit(), Digits),
      DoubleToString(OrderProfit(), 2),
      DoubleToString(OrderSwap(), 2),
      DoubleToString(OrderCommission(), 2),
      DoubleToString(netProfit, 2),
      IntegerToString(OrderMagicNumber()),
      OrderComment()
   );

   FileClose(handle);
}

#endif