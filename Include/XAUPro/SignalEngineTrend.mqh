#ifndef __XAU_SIGNALENGINE_TREND_MQH__
#define __XAU_SIGNALENGINE_TREND_MQH__

ENUM_TIMEFRAMES GetTrendExecutionTimeframe()
{
   return GetRequiredEntryTimeframe();
}

double GetTrendOpen(int shift)
{
   return iOpen(Symbol(), GetTrendExecutionTimeframe(), shift);
}

double GetTrendClose(int shift)
{
   return iClose(Symbol(), GetTrendExecutionTimeframe(), shift);
}

double GetTrendHigh(int shift)
{
   return iHigh(Symbol(), GetTrendExecutionTimeframe(), shift);
}

double GetTrendLow(int shift)
{
   return iLow(Symbol(), GetTrendExecutionTimeframe(), shift);
}

double GetTrendRange(double highPrice, double lowPrice)
{
   return highPrice - lowPrice;
}

double GetTrendBody(double openPrice, double closePrice)
{
   return MathAbs(closePrice - openPrice);
}

double GetTrendUpperWick(double openPrice, double closePrice, double highPrice)
{
   return highPrice - MathMax(openPrice, closePrice);
}

double GetTrendLowerWick(double openPrice, double closePrice, double lowPrice)
{
   return MathMin(openPrice, closePrice) - lowPrice;
}

bool IsTrendBullishRejection(double openPrice, double closePrice, double highPrice, double lowPrice)
{
   double range = GetTrendRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetTrendBody(openPrice, closePrice);
   double lowerWick = GetTrendLowerWick(openPrice, closePrice, lowPrice);
   double closePosition = (closePrice - lowPrice) / range;

   if(closePrice <= openPrice)
      return false;

   if(body < range * 0.18)
      return false;

   if(lowerWick < body * 0.60)
      return false;

   if(closePosition < 0.55)
      return false;

   return true;
}

bool IsTrendBearishRejection(double openPrice, double closePrice, double highPrice, double lowPrice)
{
   double range = GetTrendRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetTrendBody(openPrice, closePrice);
   double upperWick = GetTrendUpperWick(openPrice, closePrice, highPrice);
   double closePosition = (closePrice - lowPrice) / range;

   if(closePrice >= openPrice)
      return false;

   if(body < range * 0.18)
      return false;

   if(upperWick < body * 0.60)
      return false;

   if(closePosition > 0.45)
      return false;

   return true;
}

bool IsTrendStrongBullishConfirm(double openPrice, double closePrice, double highPrice, double lowPrice, double breakLevel)
{
   double range = GetTrendRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetTrendBody(openPrice, closePrice);
   double bodyRatio = body / range;

   if(closePrice <= openPrice)
      return false;

   if(closePrice <= breakLevel)
      return false;

   if(bodyRatio < 0.35)
      return false;

   return true;
}

bool IsTrendStrongBearishConfirm(double openPrice, double closePrice, double highPrice, double lowPrice, double breakLevel)
{
   double range = GetTrendRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetTrendBody(openPrice, closePrice);
   double bodyRatio = body / range;

   if(closePrice >= openPrice)
      return false;

   if(closePrice >= breakLevel)
      return false;

   if(bodyRatio < 0.35)
      return false;

   return true;
}

SignalResult BuildTrendSignal(bool doLog = true)
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
   result.higherBiasOk = false;

   ENUM_TIMEFRAMES execTf = GetTrendExecutionTimeframe();

   result.atrValue = iATR(Symbol(), execTf, ATRPeriod, 1);
   result.spreadPoints = (int)((Ask - Bid) / Point);
   result.emaFast = iMA(Symbol(), TrendTimeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.emaSlow = iMA(Symbol(), TrendTimeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.h4Fast = iMA(Symbol(), HigherBiasTimeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.h4Slow = iMA(Symbol(), HigherBiasTimeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.regime = DetectMarketRegime();

   if(IsSpreadSpike())
   {
      result.reason = "Spread spike detected";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   int trendDir = GetTrendDirectionForTimeframe(TrendTimeframe, FastEMA, SlowEMA);
   int higherDir = GetTrendDirectionForTimeframe(HigherBiasTimeframe, FastEMA, SlowEMA);

   result.direction = trendDir;

   if(trendDir == DIR_NONE)
   {
      result.reason = "Trend neutral";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   result.trendOk = true;

   if(UseMultiTimeframeBias)
   {
      if(higherDir == DIR_NONE || trendDir != higherDir)
      {
         result.reason = "H4/H1 bias not aligned";
         if(doLog) LogSignalDiagnostics(result);
         return result;
      }
   }

   result.higherBiasOk = true;

   if(UseRegimeFilter && (!DeveloperTestMode || !DeveloperIgnoreRegimeFilter))
   {
      if(!IsTradableRegime())
      {
         result.reason = "Regime filter blocked trade";
         if(doLog) LogSignalDiagnostics(result);
         return result;
      }
   }

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

   double ema20 = iMA(Symbol(), execTf, PullbackEMA1, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ema50 = iMA(Symbol(), execTf, PullbackEMA2, 0, MODE_EMA, PRICE_CLOSE, 1);

   double bar1Open = GetTrendOpen(1);
   double bar1Close = GetTrendClose(1);
   double bar1High = GetTrendHigh(1);
   double bar1Low = GetTrendLow(1);

   double bar2Open = GetTrendOpen(2);
   double bar2Close = GetTrendClose(2);
   double bar2High = GetTrendHigh(2);
   double bar2Low = GetTrendLow(2);

   double baseStopDistance = GetDynamicStopDistancePrice(result.atrValue);
   double baseTpDistance = GetDynamicTakeProfitDistancePrice(result.atrValue);

   if(baseStopDistance <= 0 || baseTpDistance <= 0)
   {
      result.reason = "Invalid trend stop/target profile";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   double maxExtensionDistance = result.atrValue * 0.90;
   double rrMultiplier = baseTpDistance / baseStopDistance;

   if(rrMultiplier < 1.30)
      rrMultiplier = 1.30;

   if(trendDir == DIR_BUY && higherDir == DIR_BUY)
   {
      bool pulledBack = (bar2Low <= ema20 || bar2Low <= ema50);
      bool bullishReject = IsTrendBullishRejection(bar2Open, bar2Close, bar2High, bar2Low);
      bool bullishConfirm = IsTrendStrongBullishConfirm(bar1Open, bar1Close, bar1High, bar1Low, bar2High);
      bool notOverextended = ((bar1Close - ema20) <= maxExtensionDistance);
      bool extraOk = (bar1Close > ema20 && notOverextended);

      if(DeveloperTestMode && DeveloperIgnoreRejection)
         bullishReject = true;
      if(DeveloperTestMode && DeveloperIgnoreConfirmation)
         bullishConfirm = true;
      if(DeveloperTestMode && DeveloperIgnoreExtraFilter)
         extraOk = true;

      result.pullbackOk = pulledBack;
      result.rejectionOk = bullishReject;
      result.confirmationOk = bullishConfirm;
      result.extraFilterOk = extraOk;

      if(pulledBack && bullishReject && bullishConfirm && extraOk)
      {
         double liveEntry = Ask;
         double stopAnchor = MathMin(bar1Low, bar2Low);
         double anchoredStopDistance = liveEntry - stopAnchor;
         double finalStopDistance = MathMax(baseStopDistance, anchoredStopDistance);

         if(finalStopDistance <= 0)
         {
            result.reason = "Invalid BUY stop distance";
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         double finalTpDistance = MathMax(baseTpDistance, finalStopDistance * rrMultiplier);

         result.isValid = true;
         result.direction = DIR_BUY;
         result.reason = "BUY signal";
         result.label = DeveloperTestMode ? "DevTestBuy" : "TrendPullbackBuy";
         result.entryPrice = NormalizePrice(liveEntry);
         result.stopLossPrice = NormalizePrice(liveEntry - finalStopDistance);
         result.takeProfitPrice = NormalizePrice(liveEntry + finalTpDistance);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.reason = "Buy conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   if(trendDir == DIR_SELL && higherDir == DIR_SELL)
   {
      bool pulledBack = (bar2High >= ema20 || bar2High >= ema50);
      bool bearishReject = IsTrendBearishRejection(bar2Open, bar2Close, bar2High, bar2Low);
      bool bearishConfirm = IsTrendStrongBearishConfirm(bar1Open, bar1Close, bar1High, bar1Low, bar2Low);
      bool notOverextended = ((ema20 - bar1Close) <= maxExtensionDistance);
      bool extraOk = (bar1Close < ema20 && notOverextended);

      if(DeveloperTestMode && DeveloperIgnoreRejection)
         bearishReject = true;
      if(DeveloperTestMode && DeveloperIgnoreConfirmation)
         bearishConfirm = true;
      if(DeveloperTestMode && DeveloperIgnoreExtraFilter)
         extraOk = true;

      result.pullbackOk = pulledBack;
      result.rejectionOk = bearishReject;
      result.confirmationOk = bearishConfirm;
      result.extraFilterOk = extraOk;

      if(pulledBack && bearishReject && bearishConfirm && extraOk)
      {
         double liveEntry = Bid;
         double stopAnchor = MathMax(bar1High, bar2High);
         double anchoredStopDistance = stopAnchor - liveEntry;
         double finalStopDistance = MathMax(baseStopDistance, anchoredStopDistance);

         if(finalStopDistance <= 0)
         {
            result.reason = "Invalid SELL stop distance";
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         double finalTpDistance = MathMax(baseTpDistance, finalStopDistance * rrMultiplier);

         result.isValid = true;
         result.direction = DIR_SELL;
         result.reason = "SELL signal";
         result.label = DeveloperTestMode ? "DevTestSell" : "TrendPullbackSell";
         result.entryPrice = NormalizePrice(liveEntry);
         result.stopLossPrice = NormalizePrice(liveEntry + finalStopDistance);
         result.takeProfitPrice = NormalizePrice(liveEntry - finalTpDistance);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.reason = "Sell conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   result.reason = "H4/H1 direction mismatch";
   if(doLog) LogSignalDiagnostics(result);
   return result;
}

#endif