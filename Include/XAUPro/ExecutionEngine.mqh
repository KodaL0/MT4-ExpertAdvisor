#ifndef __XAU_EXECUTIONENGINE_MQH__
#define __XAU_EXECUTIONENGINE_MQH__

bool ExecuteSignal(SignalResult &signal, double lotSize)
{
   if(lotSize <= 0)
   {
      LogSkip("Execution blocked: invalid lot size");
      return false;
   }

   if(!IsStopDistanceValid(signal.direction, signal.entryPrice, signal.stopLossPrice, signal.takeProfitPrice))
   {
      LogSkip("Execution blocked: stop distance too small for broker");
      return false;
   }

   int ticket = -1;

   if(signal.direction == DIR_BUY)
   {
      LogInfo(
         "Sending BUY | Lot=" + DoubleToString(lotSize, 2) +
         " Entry=" + DoubleToString(Ask, Digits) +
         " SL=" + DoubleToString(signal.stopLossPrice, Digits) +
         " TP=" + DoubleToString(signal.takeProfitPrice, Digits)
      );

      ticket = OrderSend(
         Symbol(),
         OP_BUY,
         lotSize,
         Ask,
         Slippage,
         signal.stopLossPrice,
         signal.takeProfitPrice,
         signal.label,
         MagicNumber,
         0,
         clrGreen
      );
   }
   else if(signal.direction == DIR_SELL)
   {
      LogInfo(
         "Sending SELL | Lot=" + DoubleToString(lotSize, 2) +
         " Entry=" + DoubleToString(Bid, Digits) +
         " SL=" + DoubleToString(signal.stopLossPrice, Digits) +
         " TP=" + DoubleToString(signal.takeProfitPrice, Digits)
      );

      ticket = OrderSend(
         Symbol(),
         OP_SELL,
         lotSize,
         Bid,
         Slippage,
         signal.stopLossPrice,
         signal.takeProfitPrice,
         signal.label,
         MagicNumber,
         0,
         clrRed
      );
   }

   if(ticket < 0)
   {
      LogError("OrderSend failed");
      return false;
   }

   RegisterTrade();
   LogTrade("Order opened ticket: " + IntegerToString(ticket));

   return true;
}

#endif