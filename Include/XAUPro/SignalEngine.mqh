#ifndef __XAU_SIGNALENGINE_MQH__
#define __XAU_SIGNALENGINE_MQH__

string DirectionToText(int dir)
{
   if(dir == DIR_BUY) return "BUY";
   if(dir == DIR_SELL) return "SELL";
   return "NONE";
}

string BoolText(bool value)
{
   return value ? "YES" : "NO";
}

double GetDynamicStopDistancePrice(double atrValue)
{
   if(UseATRStops)
      return atrValue * ATRStopMultiplier;

   return StopLossPoints * Point;
}

double GetDynamicTakeProfitDistancePrice(double atrValue)
{
   if(UseATRStops)
      return atrValue * ATRTakeProfitMultiplier;

   return TakeProfitPoints * Point;
}

void LogSignalDiagnostics(SignalResult &r)
{
   if(!EnableVerboseSignalLogs)
      return;

   Print("===== SIGNAL CHECK (M15) =====");
   Print("Direction      : ", DirectionToText(r.direction));
   Print("Trend OK       : ", BoolText(r.trendOk));
   Print("Pullback OK    : ", BoolText(r.pullbackOk));
   Print("Rejection OK   : ", BoolText(r.rejectionOk));
   Print("Confirmation OK: ", BoolText(r.confirmationOk));
   Print("Extra Filter OK: ", BoolText(r.extraFilterOk));
   Print("ATR            : ", DoubleToString(r.atrValue, 2));
   Print("Spread         : ", IntegerToString(r.spreadPoints));
   Print("EMA Fast       : ", DoubleToString(r.emaFast, 2));
   Print("EMA Slow       : ", DoubleToString(r.emaSlow, 2));
   Print("SL Price       : ", DoubleToString(r.stopLossPrice, Digits));
   Print("TP Price       : ", DoubleToString(r.takeProfitPrice, Digits));
   Print("Result         : ", r.reason);
   Print("==============================");
}

SignalResult BuildSignal(bool doLog = true)
{
   SignalResult result;

   result.isValid = false;
   result.direction = DIR_NONE;
   result.reason = "No signal";
   result.label = "";
   result.entryPrice = 0;
   result.stopLossPrice = 0;
   result.takeProfitPrice = 0;

   result.trendOk = false;
   result.pullbackOk = false;
   result.rejectionOk = false;
   result.confirmationOk = false;
   result.extraFilterOk = false;

   result.atrValue = iATR(Symbol(), PERIOD_M15, ATRPeriod, 1);
   result.spreadPoints = (int)((Ask - Bid) / Point);
   result.emaFast = iMA(Symbol(), TrendTimeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.emaSlow = iMA(Symbol(), TrendTimeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);

   int trend = GetTrendDirection();
   result.direction = trend;

   if(trend == DIR_NONE)
   {
      result.reason = "Trend neutral";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   result.trendOk = true;

   if(!DeveloperTestMode || !DeveloperIgnoreTrendStrength)
   {
      if(!IsTrendStrongEnough())
      {
         result.reason = "Trend too weak";
         if(doLog) LogSignalDiagnostics(result);
         return result;
      }
   }

   if(!DeveloperTestMode || !DeveloperIgnoreAbnormalCandle)
   {
      if(IsAbnormalCandle())
      {
         result.reason = "Abnormal candle detected";
         if(doLog) LogSignalDiagnostics(result);
         return result;
      }
   }

   double ema20 = iMA(Symbol(), PERIOD_M15, PullbackEMA1, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ema50 = iMA(Symbol(), PERIOD_M15, PullbackEMA2, 0, MODE_EMA, PRICE_CLOSE, 1);

   double bar1Open = Open[1];
   double bar1Close = Close[1];
   double bar1High = High[1];
   double bar1Low = Low[1];

   double bar2Open = Open[2];
   double bar2Close = Close[2];
   double bar2High = High[2];
   double bar2Low = Low[2];

   double stopDistance = GetDynamicStopDistancePrice(result.atrValue);
   double tpDistance = GetDynamicTakeProfitDistancePrice(result.atrValue);

   if(trend == DIR_BUY)
   {
      bool pulledBack = (bar2Low <= ema20 || bar2Low <= ema50);
      bool bullishReject = (bar2Close > bar2Open);
      bool bullishConfirm = (bar1Close > bar1Open && bar1Close > bar2High);
      bool bar1NotTooBearish = (bar1Low >= ema50 || bar1Close > ema20);

      if(DeveloperTestMode && DeveloperIgnoreRejection)
         bullishReject = true;

      if(DeveloperTestMode && DeveloperIgnoreConfirmation)
         bullishConfirm = true;

      if(DeveloperTestMode && DeveloperIgnoreExtraFilter)
         bar1NotTooBearish = true;

      result.pullbackOk = pulledBack;
      result.rejectionOk = bullishReject;
      result.confirmationOk = bullishConfirm;
      result.extraFilterOk = bar1NotTooBearish;

      if(pulledBack && bullishReject && bullishConfirm && bar1NotTooBearish)
      {
         result.isValid = true;
         result.direction = DIR_BUY;
         result.reason = "BUY signal";
         result.label = DeveloperTestMode ? "DevTestBuy" : "TrendPullbackBuy";
         result.entryPrice = Ask;
         result.stopLossPrice = NormalizePrice(Ask - stopDistance);
         result.takeProfitPrice = NormalizePrice(Ask + tpDistance);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.reason = "Buy conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   if(trend == DIR_SELL)
   {
      bool pulledBack = (bar2High >= ema20 || bar2High >= ema50);
      bool bearishReject = (bar2Close < bar2Open);
      bool bearishConfirm = (bar1Close < bar1Open && bar1Close < bar2Low);
      bool bar1NotTooBullish = (bar1High <= ema50 || bar1Close < ema20);

      if(DeveloperTestMode && DeveloperIgnoreRejection)
         bearishReject = true;

      if(DeveloperTestMode && DeveloperIgnoreConfirmation)
         bearishConfirm = true;

      if(DeveloperTestMode && DeveloperIgnoreExtraFilter)
         bar1NotTooBullish = true;

      result.pullbackOk = pulledBack;
      result.rejectionOk = bearishReject;
      result.confirmationOk = bearishConfirm;
      result.extraFilterOk = bar1NotTooBullish;

      if(pulledBack && bearishReject && bearishConfirm && bar1NotTooBullish)
      {
         result.isValid = true;
         result.direction = DIR_SELL;
         result.reason = "SELL signal";
         result.label = DeveloperTestMode ? "DevTestSell" : "TrendPullbackSell";
         result.entryPrice = Bid;
         result.stopLossPrice = NormalizePrice(Bid + stopDistance);
         result.takeProfitPrice = NormalizePrice(Bid - tpDistance);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.reason = "Sell conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   if(doLog) LogSignalDiagnostics(result);
   return result;
}

#endif