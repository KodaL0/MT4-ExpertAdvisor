#ifndef __XAU_SIGNALENGINE_SNIPER_MQH__
#define __XAU_SIGNALENGINE_SNIPER_MQH__

ENUM_TIMEFRAMES GetSniperExecutionTimeframe()
{
   return PERIOD_M5;
}

double GetSniperOpen(int shift)
{
   return iOpen(Symbol(), GetSniperExecutionTimeframe(), shift);
}

double GetSniperClose(int shift)
{
   return iClose(Symbol(), GetSniperExecutionTimeframe(), shift);
}

double GetSniperHigh(int shift)
{
   return iHigh(Symbol(), GetSniperExecutionTimeframe(), shift);
}

double GetSniperLow(int shift)
{
   return iLow(Symbol(), GetSniperExecutionTimeframe(), shift);
}

double GetCandleRange(double high, double low)
{
   return high - low;
}

double GetCandleBody(double openPrice, double closePrice)
{
   return MathAbs(closePrice - openPrice);
}

double GetUpperWick(double openPrice, double closePrice, double highPrice)
{
   return highPrice - MathMax(openPrice, closePrice);
}

double GetLowerWick(double openPrice, double closePrice, double lowPrice)
{
   return MathMin(openPrice, closePrice) - lowPrice;
}

bool IsBullishRejectionCandle(double openPrice, double closePrice, double highPrice, double lowPrice)
{
   double range = GetCandleRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetCandleBody(openPrice, closePrice);
   double lowerWick = GetLowerWick(openPrice, closePrice, lowPrice);
   double closePosition = (closePrice - lowPrice) / range;

   if(closePrice <= openPrice)
      return false;

   if(body < range * 0.10)
      return false;

   if(lowerWick < body * 0.35)
      return false;

   if(closePosition < 0.50)
      return false;

   return true;
}

bool IsBearishRejectionCandle(double openPrice, double closePrice, double highPrice, double lowPrice)
{
   double range = GetCandleRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetCandleBody(openPrice, closePrice);
   double upperWick = GetUpperWick(openPrice, closePrice, highPrice);
   double closePosition = (closePrice - lowPrice) / range;

   if(closePrice >= openPrice)
      return false;

   if(body < range * 0.10)
      return false;

   if(upperWick < body * 0.35)
      return false;

   if(closePosition > 0.50)
      return false;

   return true;
}

bool IsStrongBullishBreakCandle(double openPrice, double closePrice, double highPrice, double lowPrice, double breakLevel)
{
   double range = GetCandleRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetCandleBody(openPrice, closePrice);
   double bodyRatio = body / range;

   if(closePrice <= openPrice)
      return false;

   if(closePrice <= breakLevel && closePrice <= highPrice - (range * 0.20))
      return false;

   if(bodyRatio < 0.20)
      return false;

   return true;
}

bool IsStrongBearishBreakCandle(double openPrice, double closePrice, double highPrice, double lowPrice, double breakLevel)
{
   double range = GetCandleRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetCandleBody(openPrice, closePrice);
   double bodyRatio = body / range;

   if(closePrice >= openPrice)
      return false;

   if(closePrice >= breakLevel && closePrice >= lowPrice + (range * 0.20))
      return false;

   if(bodyRatio < 0.20)
      return false;

   return true;
}

bool IsSniperChoppy(double emaPull1, double emaPull2)
{
   double emaSeparationPoints = MathAbs(emaPull1 - emaPull2) / Point;

   if(UseEMASeparationFilter)
   {
      double requiredSeparation = MathMax(10.0, MinEMASeparationPoints * 0.25);
      if(emaSeparationPoints < requiredSeparation)
         return true;
   }

   int directionChanges = 0;
   int prevDir = 0;

   for(int shift = 4; shift >= 1; shift--)
   {
      double openPrice = GetSniperOpen(shift);
      double closePrice = GetSniperClose(shift);

      int dir = 0;
      if(closePrice > openPrice) dir = 1;
      else if(closePrice < openPrice) dir = -1;

      if(prevDir != 0 && dir != 0 && dir != prevDir)
         directionChanges++;

      if(dir != 0)
         prevDir = dir;
   }

   if(directionChanges >= 4)
      return true;

   return false;
}

double GetRecentRangeHigh(int barsBack)
{
   double highest = GetSniperHigh(1);

   for(int i = 2; i <= barsBack; i++)
   {
      double h = GetSniperHigh(i);
      if(h > highest)
         highest = h;
   }

   return highest;
}

double GetRecentRangeLow(int barsBack)
{
   double lowest = GetSniperLow(1);

   for(int i = 2; i <= barsBack; i++)
   {
      double l = GetSniperLow(i);
      if(l < lowest)
         lowest = l;
   }

   return lowest;
}

bool IsBullishBreakoutSetup(double bar1Open, double bar1Close, double bar1High, double bar1Low, double emaPull1, double atrValue)
{
   double recentHigh = GetRecentRangeHigh(4);
   double range = bar1High - bar1Low;

   if(range <= 0 || atrValue <= 0)
      return false;

   bool strongBullishBody = (bar1Close > bar1Open) && ((bar1Close - bar1Open) >= range * 0.35);
   bool brokeRange = (bar1Close > recentHigh);
   bool notTooExtended = ((bar1Close - emaPull1) <= atrValue * 1.10);

   return (strongBullishBody && brokeRange && notTooExtended);
}

bool IsBearishBreakoutSetup(double bar1Open, double bar1Close, double bar1High, double bar1Low, double emaPull1, double atrValue)
{
   double recentLow = GetRecentRangeLow(4);
   double range = bar1High - bar1Low;

   if(range <= 0 || atrValue <= 0)
      return false;

   bool strongBearishBody = (bar1Close < bar1Open) && ((bar1Open - bar1Close) >= range * 0.35);
   bool brokeRange = (bar1Close < recentLow);
   bool notTooExtended = ((emaPull1 - bar1Close) <= atrValue * 1.10);

   return (strongBearishBody && brokeRange && notTooExtended);
}

SignalResult BuildSniperSignal(bool doLog = true)
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

   result.atrValue = iATR(Symbol(), GetSniperExecutionTimeframe(), ATRPeriod, 1);
   result.spreadPoints = (int)((Ask - Bid) / Point);
   result.emaFast = iMA(Symbol(), SniperBiasTimeframe, SniperFastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.emaSlow = iMA(Symbol(), SniperBiasTimeframe, SniperSlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.h4Fast = 0;
   result.h4Slow = 0;
   result.regime = REGIME_UNKNOWN;

   if(IsSpreadSpike())
   {
      result.reason = "Spread spike detected";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   if(result.atrValue <= 0)
   {
      result.reason = "Invalid ATR value";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   int bias = GetTrendDirectionForTimeframe(SniperBiasTimeframe, SniperFastEMA, SniperSlowEMA);
   result.direction = bias;

   if(bias == DIR_NONE)
   {
      result.reason = "Sniper bias neutral";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   result.trendOk = true;
   result.higherBiasOk = true;

   double emaPull1 = iMA(Symbol(), GetSniperExecutionTimeframe(), SniperPullbackEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double emaPull2 = iMA(Symbol(), GetSniperExecutionTimeframe(), SniperPullbackEMA2, 0, MODE_EMA, PRICE_CLOSE, 1);

   double bar1Open = GetSniperOpen(1);
   double bar1Close = GetSniperClose(1);
   double bar1High = GetSniperHigh(1);
   double bar1Low = GetSniperLow(1);

   double bar2Open = GetSniperOpen(2);
   double bar2Close = GetSniperClose(2);
   double bar2High = GetSniperHigh(2);
   double bar2Low = GetSniperLow(2);

   double baseStopDistance;
   double baseTpDistance;

   if(UseSniperATRProfile)
   {
      baseStopDistance = result.atrValue * SniperATRStopMultiplier;
      baseTpDistance = result.atrValue * SniperATRTakeProfitMultiplier;
   }
   else
   {
      baseStopDistance = GetDynamicStopDistancePrice(result.atrValue);
      baseTpDistance = GetDynamicTakeProfitDistancePrice(result.atrValue);
   }

   if(baseStopDistance <= 0 || baseTpDistance <= 0)
   {
      result.reason = "Invalid sniper stop/target profile";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   bool isChoppy = IsSniperChoppy(emaPull1, emaPull2);
   double maxExtensionDistance = result.atrValue * 0.90;
   double rrMultiplier = baseTpDistance / baseStopDistance;

   if(rrMultiplier < 1.05)
      rrMultiplier = 1.05;

   if(bias == DIR_BUY)
   {
      bool pulledBack =
         (bar2Low <= emaPull1) ||
         (SniperUseSecondEMA && bar2Low <= emaPull2) ||
         (bar1Low <= emaPull1);

      bool bullishReject =
         IsBullishRejectionCandle(bar2Open, bar2Close, bar2High, bar2Low) ||
         IsBullishRejectionCandle(bar1Open, bar1Close, bar1High, bar1Low);

      bool bullishConfirm =
         IsStrongBullishBreakCandle(bar1Open, bar1Close, bar1High, bar1Low, bar2High) ||
         (bar1Close > emaPull1 && bar1Close > bar1Open) ||
         (bar1High > bar2High);

      bool bullishBreakout =
         IsBullishBreakoutSetup(bar1Open, bar1Close, bar1High, bar1Low, emaPull1, result.atrValue);

      bool notOverextended = ((bar1Close - emaPull1) <= maxExtensionDistance);

      bool extraOk =
         (!isChoppy) &&
         notOverextended;

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

      bool allowPullbackBuy = (pulledBack && bullishReject && bullishConfirm && extraOk);
      bool allowBreakoutBuy = (bullishBreakout && !isChoppy);

      if(allowPullbackBuy || allowBreakoutBuy)

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
         result.reason = allowBreakoutBuy ? "BUY breakout signal" : "BUY signal";
         result.label = allowBreakoutBuy
               ? (DeveloperTestMode ? "DevSniperBreakoutBuy" : "SniperBreakoutBuy")
               : (DeveloperTestMode ? "DevSniperBuy" : "SniperBuy");
         result.entryPrice = NormalizePrice(liveEntry);
         result.stopLossPrice = NormalizePrice(liveEntry - finalStopDistance);
         result.takeProfitPrice = NormalizePrice(liveEntry + finalTpDistance);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.reason = "Sniper buy conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   if(bias == DIR_SELL)
   {
      bool pulledBack =
         (bar2High >= emaPull1) ||
         (SniperUseSecondEMA && bar2High >= emaPull2) ||
         (bar1High >= emaPull1);

      bool bearishReject =
         IsBearishRejectionCandle(bar2Open, bar2Close, bar2High, bar2Low) ||
         IsBearishRejectionCandle(bar1Open, bar1Close, bar1High, bar1Low);

      bool bearishConfirm =
         IsStrongBearishBreakCandle(bar1Open, bar1Close, bar1High, bar1Low, bar2Low) ||
         (bar1Close < emaPull1 && bar1Close < bar1Open) ||
         (bar1Low < bar2Low);

      bool bearishBreakout =
         IsBearishBreakoutSetup(bar1Open, bar1Close, bar1High, bar1Low, emaPull1, result.atrValue);

      bool notOverextended = ((emaPull1 - bar1Close) <= maxExtensionDistance);

      bool extraOk =
         (!isChoppy) &&
         notOverextended;

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

      bool allowPullbackSell = (pulledBack && bearishReject && bearishConfirm && extraOk);
      bool allowBreakoutSell = (bearishBreakout && !isChoppy);

      if(allowPullbackSell || allowBreakoutSell)

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
         result.reason = allowBreakoutSell ? "SELL breakout signal" : "SELL signal";
         result.label = allowBreakoutSell
               ? (DeveloperTestMode ? "DevSniperBreakoutSell" : "SniperBreakoutSell")
               : (DeveloperTestMode ? "DevSniperSell" : "SniperSell");
         result.entryPrice = NormalizePrice(liveEntry);
         result.stopLossPrice = NormalizePrice(liveEntry + finalStopDistance);
         result.takeProfitPrice = NormalizePrice(liveEntry - finalTpDistance);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.reason = "Sniper sell conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   result.reason = "Sniper no signal";
   if(doLog) LogSignalDiagnostics(result);
   return result;
}

#endif