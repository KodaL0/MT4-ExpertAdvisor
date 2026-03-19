#ifndef __XAU_EXECUTIONENGINE_MQH__
#define __XAU_EXECUTIONENGINE_MQH__

string GetTradeErrorText(int err)
{
   switch(err)
   {
      case 0:   return "No error";
      case 1:   return "No result";
      case 2:   return "Common error";
      case 3:   return "Invalid trade parameters";
      case 4:   return "Trade server busy";
      case 5:   return "Old terminal version";
      case 6:   return "No connection";
      case 8:   return "Too frequent requests";
      case 64:  return "Account disabled";
      case 65:  return "Invalid account";
      case 128: return "Trade timeout";
      case 129: return "Invalid price";
      case 130: return "Invalid stops";
      case 131: return "Invalid volume";
      case 132: return "Market closed";
      case 133: return "Trade disabled";
      case 134: return "Not enough money";
      case 135: return "Price changed";
      case 136: return "Off quotes";
      case 137: return "Broker busy";
      case 138: return "Requote";
      case 139: return "Order locked";
      case 141: return "Too many requests";
      case 145: return "Modification denied";
      case 146: return "Trade context busy";
      case 148: return "Too many orders";
   }

   return "Unknown error";
}

bool IsRetryableTradeError(int err)
{
   return (err == 4 || err == 6 || err == 128 || err == 135 || err == 136 || err == 137 || err == 138 || err == 146);
}

bool SendSingleOrder(SignalResult &signal, double lotSize, string customLabel, double customTP)
{
   if(lotSize <= 0)
   {
      LogSkip("Execution blocked: invalid lot size");
      return false;
   }

   lotSize = NormalizeLot(lotSize);

   if(lotSize <= 0)
   {
      LogSkip("Execution blocked: normalized lot size invalid");
      return false;
   }

   if(!HasEnoughFreeMarginForLot(signal.direction, lotSize))
   {
      LogSkip("Execution blocked: insufficient free margin");
      return false;
   }

   RefreshRates();

   if(!IsSpreadOk())
   {
      LogSkip("Execution blocked: spread too high at send time");
      return false;
   }

   double liveEntry = 0.0;

   if(signal.direction == DIR_BUY)
      liveEntry = Ask;
   else if(signal.direction == DIR_SELL)
      liveEntry = Bid;
   else
   {
      LogSkip("Execution blocked: invalid signal direction");
      return false;
   }

   signal.entryPrice = NormalizePrice(liveEntry);
   signal.stopLossPrice = NormalizePrice(signal.stopLossPrice);
   customTP = NormalizePrice(customTP);

   if(!IsStopDistanceValid(signal.direction, signal.entryPrice, signal.stopLossPrice, customTP))
   {
      LogSkip("Execution blocked: stop distance too small for broker");
      return false;
   }

   int ticket = -1;
   int maxAttempts = 2;

   for(int attempt = 1; attempt <= maxAttempts; attempt++)
   {
      RefreshRates();

      double sendPrice = 0.0;
      if(signal.direction == DIR_BUY)
         sendPrice = Ask;
      else
         sendPrice = Bid;

      sendPrice = NormalizePrice(sendPrice);
      signal.entryPrice = sendPrice;

      LogInfo(
         "Sending " + DirectionToText(signal.direction) +
         " | Attempt=" + IntegerToString(attempt) +
         " Label=" + customLabel +
         " | Lot=" + DoubleToString(lotSize, 2) +
         " Entry=" + DoubleToString(sendPrice, Digits) +
         " SL=" + DoubleToString(signal.stopLossPrice, Digits) +
         " TP=" + DoubleToString(customTP, Digits)
      );

      ResetLastError();

      if(signal.direction == DIR_BUY)
      {
         ticket = OrderSend(
            Symbol(),
            OP_BUY,
            lotSize,
            sendPrice,
            Slippage,
            signal.stopLossPrice,
            customTP,
            customLabel,
            MagicNumber,
            0,
            clrGreen
         );
      }
      else if(signal.direction == DIR_SELL)
      {
         ticket = OrderSend(
            Symbol(),
            OP_SELL,
            lotSize,
            sendPrice,
            Slippage,
            signal.stopLossPrice,
            customTP,
            customLabel,
            MagicNumber,
            0,
            clrRed
         );
      }

      if(ticket >= 0)
      {
         RegisterTrade();
         LogTrade("Order opened ticket: " + IntegerToString(ticket) + " | " + customLabel);
         return true;
      }

      int err = GetLastError();
      string errText = GetTradeErrorText(err);

      LogError("OrderSend failed | Attempt=" + IntegerToString(attempt) +
               " | Label=" + customLabel +
               " | Code=" + IntegerToString(err) +
               " | Reason=" + errText);

      ResetLastError();

      if(!IsRetryableTradeError(err) || attempt == maxAttempts)
         break;

      Sleep(500);
   }

   return false;
}

bool ExecuteSignal(SignalResult &signal, double lotSize)
{
   if(lotSize <= 0)
   {
      LogSkip("Execution blocked: invalid lot size");
      return false;
   }

   lotSize = NormalizeLot(lotSize);

   if(lotSize <= 0)
   {
      LogSkip("Execution blocked: normalized lot size invalid");
      return false;
   }

   // Normal signal = 1 trade
   if(!signal.isStrongSignal)
   {
      return SendSingleOrder(signal, lotSize, signal.label, signal.takeProfitPrice);
   }

   // Strong signal = 2 trades
   double splitLot = NormalizeLot(lotSize / 2.0);

   if(splitLot <= 0)
   {
      LogSkip("Execution blocked: split lot invalid");
      return false;
   }

   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   if(splitLot < minLot)
   {
      LogSkip("Execution blocked: split lot below broker minimum");
      return false;
   }

   string baseLabel = signal.label;
   string tpLabel = baseLabel + "_TP";
   string runLabel = baseLabel + "_RUN";

   bool tpOk = SendSingleOrder(signal, splitLot, tpLabel, signal.takeProfitPrice);
   bool runOk = SendSingleOrder(signal, splitLot, runLabel, 0);

   if(tpOk || runOk)
      return true;

   return false;
}

#endif