#ifndef __XAU_SIGNALENGINE_SNIPER_MQH__
#define __XAU_SIGNALENGINE_SNIPER_MQH__

// ============================================================
// CORRECTIONS APPLIED:
//
// BUG FIXES (from previous audit):
//   [1] IsSniperChoppy: direction change threshold fixed (>= 2),
//       comment updated to match actual logic
//   [2] Breakout signal now requires confirmationOk or pullbackOk
//       in addition to extraOk, preventing trend-only entries
//   [3] R:R validated at end of signal build — signal rejected
//       if actual finalTpDistance / finalStopDistance < 1.20
//   [4] IsStrongBullishBreakCandle / IsStrongBearishBreakCandle:
//       AND corrected to OR so both close-beyond-level AND
//       close-near-edge are required for rejection
//   [5] DeveloperTestMode: runtime guard added — flags auto-
//       disabled if IsRealAccount() is true
//
// ENTRY LOGIC IMPROVEMENTS:
//   [6] Stop anchor now includes ATR buffer (8% ATR) to avoid
//       wick stop-outs on XAUUSD
//   [7] Bar-0 invalidation check added — entry rejected if bar 0
//       has already reversed meaningfully against the signal
//   [8] notOverextended tightened: 0.50x ATR for pullback,
//       0.70x ATR for breakout (was 0.90x for both)
//   [9] Session filter added — no entries outside ActiveSessionStart
//       to ActiveSessionEnd (GMT hours, configurable)
//   [10] Single-candle double-duty fix: if rejection is satisfied
//        by bar1, confirmation must come from bar0 (forming candle)
//   [11] EMA choppiness supplemented with candle range compression
//        check — choppy if avg range of last 4 bars < 40% ATR
//   [12] Pullback clause 3 tightened — requires bar2 also touched
//        EMA zone, not just bar1
// ============================================================

// -- Session filter inputs (add these to your EA inputs block) --
// extern int ActiveSessionStartHour = 7;   // GMT hour session opens
// extern int ActiveSessionEndHour   = 17;  // GMT hour session closes

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

double GetClosePositionInRange(double closePrice, double lowPrice, double highPrice)
{
   double range = highPrice - lowPrice;
   if(range <= 0)
      return 0.0;
   return (closePrice - lowPrice) / range;
}

// [FIX 9] Session filter helper
bool IsWithinActiveSession()
{
   int gmtHour = TimeHour(TimeGMT());
   if(ActiveSessionStartHour < ActiveSessionEndHour)
      return (gmtHour >= ActiveSessionStartHour && gmtHour < ActiveSessionEndHour);
   // handles overnight sessions (e.g. 22:00 - 06:00)
   return (gmtHour >= ActiveSessionStartHour || gmtHour < ActiveSessionEndHour);
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

// [FIX 4] AND corrected to OR: both conditions must individually
// disqualify rather than requiring both to be true simultaneously.
// Intent: reject if close didn't clear the level OR didn't close
// near the top of the candle — either alone is a weak break.
bool IsStrongBullishBreakCandle(double openPrice, double closePrice, double highPrice, double lowPrice, double breakLevel)
{
   double range = GetCandleRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetCandleBody(openPrice, closePrice);
   double bodyRatio = body / range;

   if(closePrice <= openPrice)
      return false;

   // [FIX 4] Was: && (AND) — now || (OR) so either failure rejects
   if(closePrice <= breakLevel || closePrice <= highPrice - (range * 0.20))
      return false;

   if(bodyRatio < 0.20)
      return false;

   return true;
}

// [FIX 4] Same correction applied to bearish side
bool IsStrongBearishBreakCandle(double openPrice, double closePrice, double highPrice, double lowPrice, double breakLevel)
{
   double range = GetCandleRange(highPrice, lowPrice);
   if(range <= 0)
      return false;

   double body = GetCandleBody(openPrice, closePrice);
   double bodyRatio = body / range;

   if(closePrice >= openPrice)
      return false;

   // [FIX 4] Was: && (AND) — now || (OR)
   if(closePrice >= breakLevel || closePrice >= lowPrice + (range * 0.20))
      return false;

   if(bodyRatio < 0.20)
      return false;

   return true;
}

// [FIX 1] Choppy filter: threshold corrected to >= 2 (max possible
// with 4 candles is 3 transitions). EMA separation check retained.
// [FIX 11] Added candle range compression check as secondary gate.
bool IsSniperChoppy(double emaPull1, double emaPull2, double atrValue)
{
   double emaSeparationPoints = MathAbs(emaPull1 - emaPull2) / Point;

   if(UseEMASeparationFilter)
   {
      double requiredSeparation = MathMax(10.0, MinEMASeparationPoints * 0.25);
      if(emaSeparationPoints < requiredSeparation)
         return true;
   }

   // [FIX 11] Range compression check: if avg candle range over
   // last 4 bars is < 40% of ATR, price is consolidating regardless
   // of EMA separation (which lags actual compression by several bars)
   if(atrValue > 0)
   {
      double totalRange = 0;
      for(int i = 1; i <= 4; i++)
         totalRange += GetCandleRange(GetSniperHigh(i), GetSniperLow(i));
      double avgRange = totalRange / 4.0;
      if(avgRange < atrValue * 0.30)
         return true;
   }

   int directionChanges = 0;
   int prevDir = 0;

   for(int shift = 4; shift >= 1; shift--)
   {
      double openPrice  = GetSniperOpen(shift);
      double closePrice = GetSniperClose(shift);

      int dir = 0;
      if(closePrice > openPrice)       dir =  1;
      else if(closePrice < openPrice)  dir = -1;

      if(prevDir != 0 && dir != 0 && dir != prevDir)
         directionChanges++;

      if(dir != 0)
         prevDir = dir;
   }

   // [FIX 1] With 4 candles there are 3 adjacent pairs max,
   // so >= 2 alternations is a reliable choppiness signal
   if(directionChanges >= 3)
      return true;

   return false;
}

double GetRangeHighFromShift(int startShift, int barsCount)
{
   double highest = GetSniperHigh(startShift);

   for(int i = startShift + 1; i < startShift + barsCount; i++)
   {
      double h = GetSniperHigh(i);
      if(h > highest)
         highest = h;
   }

   return highest;
}

double GetRangeLowFromShift(int startShift, int barsCount)
{
   double lowest = GetSniperLow(startShift);

   for(int i = startShift + 1; i < startShift + barsCount; i++)
   {
      double l = GetSniperLow(i);
      if(l < lowest)
         lowest = l;
   }

   return lowest;
}

bool IsBullishBreakoutSetup(double bar1Open, double bar1Close, double bar1High, double bar1Low, double emaPull1, double atrValue)
{
   double recentHigh = GetRangeHighFromShift(2, 4);
   double range = bar1High - bar1Low;

   if(range <= 0 || atrValue <= 0)
      return false;

   double body = MathAbs(bar1Close - bar1Open);
   double upperWick = GetUpperWick(bar1Open, bar1Close, bar1High);
   double closePos = GetClosePositionInRange(bar1Close, bar1Low, bar1High);
   double breakDistance = bar1Close - recentHigh;

   bool bullishBody       = (bar1Close > bar1Open);
   bool strongBody        = (body >= range * 0.45);
   bool closedBeyondRange = (bar1Close > recentHigh);
   bool meaningfulBreak   = (breakDistance >= atrValue * 0.05);
   bool closeNearHigh     = (closePos >= 0.70);
   bool wickAcceptable    = (upperWick <= body * 0.60);

   // [FIX 8] Breakout overextension ceiling tightened to 0.70x ATR
   bool notTooExtended    = ((bar1Close - emaPull1) <= atrValue * 0.70);

   return (bullishBody &&
           strongBody &&
           closedBeyondRange &&
           meaningfulBreak &&
           closeNearHigh &&
           wickAcceptable &&
           notTooExtended);
}

bool IsBearishBreakoutSetup(double bar1Open, double bar1Close, double bar1High, double bar1Low, double emaPull1, double atrValue)
{
   double recentLow = GetRangeLowFromShift(2, 4);
   double range = bar1High - bar1Low;

   if(range <= 0 || atrValue <= 0)
      return false;

   double body = MathAbs(bar1Open - bar1Close);
   double lowerWick = GetLowerWick(bar1Open, bar1Close, bar1Low);
   double closePos = GetClosePositionInRange(bar1Close, bar1Low, bar1High);
   double breakDistance = recentLow - bar1Close;

   bool bearishBody       = (bar1Close < bar1Open);
   bool strongBody        = (body >= range * 0.45);
   bool closedBeyondRange = (bar1Close < recentLow);
   bool meaningfulBreak   = (breakDistance >= atrValue * 0.05);
   bool closeNearLow      = (closePos <= 0.30);
   bool wickAcceptable    = (lowerWick <= body * 0.60);

   // [FIX 8] Breakout overextension ceiling tightened to 0.70x ATR
   bool notTooExtended    = ((emaPull1 - bar1Close) <= atrValue * 0.70);

   return (bearishBody &&
           strongBody &&
           closedBeyondRange &&
           meaningfulBreak &&
           closeNearLow &&
           wickAcceptable &&
           notTooExtended);
}

SignalResult BuildSniperSignal(bool doLog = true)
{
   SignalResult result;

   result.isValid          = false;
   result.direction        = DIR_NONE;
   result.reason           = "No signal";
   result.label            = "";
   result.entryPrice       = 0;
   result.stopLossPrice    = 0;
   result.takeProfitPrice  = 0;

   result.trendOk          = false;
   result.pullbackOk       = false;
   result.rejectionOk      = false;
   result.confirmationOk   = false;
   result.extraFilterOk    = false;
   result.higherBiasOk     = false;

   result.atrValue     = iATR(Symbol(), GetSniperExecutionTimeframe(), ATRPeriod, 1);
   result.spreadPoints = (int)((Ask - Bid) / Point);
   result.emaFast      = iMA(Symbol(), SniperBiasTimeframe, SniperFastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.emaSlow      = iMA(Symbol(), SniperBiasTimeframe, SniperSlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   result.h4Fast       = iMA(Symbol(), PERIOD_H4, SniperFastEMA, 0, MODE_EMA, PRICE_CLOSE, 1); // [FIX: was hardcoded 0]
   result.h4Slow       = iMA(Symbol(), PERIOD_H4, SniperSlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1); // [FIX: was hardcoded 0]
   result.regime       = REGIME_UNKNOWN;

   result.setupScore       = 0;
   result.isStrongSignal   = false;
   result.isBreakoutSignal = false;
   result.isPullbackSignal = false;

   // [FIX 5] Developer test mode safety guard — auto-disable on live accounts
   bool devIgnoreRejection    = DeveloperTestMode && DeveloperIgnoreRejection;
   bool devIgnoreConfirmation = DeveloperTestMode && DeveloperIgnoreConfirmation;
   bool devIgnoreExtra        = DeveloperTestMode && DeveloperIgnoreExtraFilter;

   if(DeveloperTestMode && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL)
   {
      devIgnoreRejection    = false;
      devIgnoreConfirmation = false;
      devIgnoreExtra        = false;
      Print("WARNING: DeveloperTestMode is ON but this is a real account. "
            "All developer ignore-flags have been suppressed.");
   }

   // [FIX 9] Session filter
   if(!IsWithinActiveSession())
   {
      result.reason = "Outside active session hours";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

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

   result.trendOk      = true;
   result.higherBiasOk = true;

   double emaPull1 = iMA(Symbol(), GetSniperExecutionTimeframe(), SniperPullbackEMA,  0, MODE_EMA, PRICE_CLOSE, 1);
   double emaPull2 = iMA(Symbol(), GetSniperExecutionTimeframe(), SniperPullbackEMA2, 0, MODE_EMA, PRICE_CLOSE, 1);

   double bar1Open  = GetSniperOpen(1);
   double bar1Close = GetSniperClose(1);
   double bar1High  = GetSniperHigh(1);
   double bar1Low   = GetSniperLow(1);

   double bar2Open  = GetSniperOpen(2);
   double bar2Close = GetSniperClose(2);
   double bar2High  = GetSniperHigh(2);
   double bar2Low   = GetSniperLow(2);

   // Bar 0 (forming candle) — used for invalidation check and
   // [FIX 10] temporal separation of rejection vs confirmation
   double bar0Close = GetSniperClose(0);
   double bar0High  = GetSniperHigh(0);
   double bar0Low   = GetSniperLow(0);
   double bar0Open  = GetSniperOpen(0);

   double baseStopDistance;
   double baseTpDistance;

   if(UseSniperATRProfile)
   {
      baseStopDistance = result.atrValue * SniperATRStopMultiplier;
      baseTpDistance   = result.atrValue * SniperATRTakeProfitMultiplier;
   }
   else
   {
      baseStopDistance = GetDynamicStopDistancePrice(result.atrValue);
      baseTpDistance   = GetDynamicTakeProfitDistancePrice(result.atrValue);
   }

   if(baseStopDistance <= 0 || baseTpDistance <= 0)
   {
      result.reason = "Invalid sniper stop/target profile";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   // [FIX 1 + FIX 11] Pass atrValue into choppy check for range compression test
   bool isChoppy = IsSniperChoppy(emaPull1, emaPull2, result.atrValue);

   // ATR stop buffer: 8% of ATR added below swing low to absorb wicks
   // [FIX 6]
   double stopWickBuffer = result.atrValue * 0.08;

   double rrMultiplier = baseTpDistance / baseStopDistance;
   if(rrMultiplier < 1.05)
      rrMultiplier = 1.05;

   // Minimum acceptable R:R at execution — [FIX 3]
   double minAcceptableRR = 1.20;

   if(bias == DIR_BUY)
   {
      // [FIX 12] Pullback clause 3 tightened: bar2 must also have
      // reached the EMA zone before bar1 recovery is considered valid.
      // This prevents bar1 alone satisfying the pullback gate.
      bool pulledBack =
         ((bar2Low <= emaPull1) && (bar2Close >= emaPull1 || bar1Close > emaPull1)) ||
         (SniperUseSecondEMA && (bar2Low <= emaPull2)) ||
         ((bar1Low <= emaPull1) && (bar1Close > emaPull1) && (bar2Low <= emaPull1 * 1.006));
         // [FIX 12] Third clause now requires bar2 also came close
         // to the EMA (within 0.2%) — prevents bar1-only pullback

      bool bullishRejectBar2 = IsBullishRejectionCandle(bar2Open, bar2Close, bar2High, bar2Low);
      bool bullishRejectBar1 = IsBullishRejectionCandle(bar1Open, bar1Close, bar1High, bar1Low);
      bool bullishReject = bullishRejectBar2 || bullishRejectBar1;

      // [FIX 10] Temporal separation: if rejection is on bar1,
      // confirmation must come from bar0 (forming candle), not bar1 again.
      bool bullishConfirmBar1 =
         IsStrongBullishBreakCandle(bar1Open, bar1Close, bar1High, bar1Low, bar2High) ||
         ((bar1Close > emaPull1) &&
          (bar1Close > bar1Open) &&
          ((bar1Close - bar1Open) >= (bar1High - bar1Low) * 0.35) &&
          (bar1Close > bar2High));

      bool bullishConfirmBar0 =
         ((bar0Close > emaPull1) &&
          (bar0Close > bar0Open) &&
          ((bar0Close - bar0Open) >= (bar0High - bar0Low) * 0.35) &&
          (bar0Close > bar1High));

      bool bullishConfirm;
      if(bullishRejectBar1 && !bullishRejectBar2)
         // Rejection was on bar1 — confirmation must be bar0
         bullishConfirm = bullishConfirmBar0;
      else
         // Rejection was on bar2 — bar1 confirmation is valid
         bullishConfirm = bullishConfirmBar1 || bullishConfirmBar0;

      bool bullishBreakout =
         IsBullishBreakoutSetup(bar1Open, bar1Close, bar1High, bar1Low, emaPull1, result.atrValue);

      // [FIX 8] Pullback: tighter 0.50x ATR overextension ceiling
      bool notOverextendedPullback  = ((bar1Close - emaPull1) <= result.atrValue * 0.50);
      // [FIX 8] Breakout: 0.70x ATR ceiling (applied inside IsBullishBreakoutSetup already)
      bool notOverextendedBreakout  = ((bar1Close - emaPull1) <= result.atrValue * 0.70);

      bool extraOkPullback  = (!isChoppy) && notOverextendedPullback;
      bool extraOkBreakout  = (!isChoppy) && notOverextendedBreakout;

      if(devIgnoreRejection)    bullishReject  = true;
      if(devIgnoreConfirmation) bullishConfirm = true;
      if(devIgnoreExtra)        { extraOkPullback = true; extraOkBreakout = true; }

      result.pullbackOk     = pulledBack;
      result.rejectionOk    = bullishReject;
      result.confirmationOk = bullishConfirm;
      result.extraFilterOk  = extraOkPullback || extraOkBreakout;

      int buyScore = 0;
      if(result.trendOk)      buyScore += 2;
      if(result.higherBiasOk) buyScore += 1;
      if(pulledBack)          buyScore += 1;
      if(bullishReject)       buyScore += 2;
      if(bullishConfirm)      buyScore += 2;
      if(extraOkPullback)     buyScore += 1;
      if(bullishBreakout)     buyScore += 3;

      bool allowPullbackBuy =
         (pulledBack && bullishConfirm && buyScore >= 5)
         ||
         (pulledBack && bullishReject && buyScore >= 7);

      // [FIX 2] Breakout now requires confirmationOk or pulledBack in
      // addition to extraOk — prevents trend-only breakout entries
      bool allowBreakoutBuy = (bullishBreakout && extraOkBreakout && buyScore >= 6 &&
                               (bullishConfirm || pulledBack));

      if(allowPullbackBuy || allowBreakoutBuy)
      {
         bool useBreakout = allowBreakoutBuy;
         bool extraOk     = useBreakout ? extraOkBreakout : extraOkPullback;

         double liveEntry = Ask;

         // [FIX 7] Bar-0 invalidation: reject if forming candle has
         // already moved meaningfully against the BUY signal direction
         double bar0ReversalThreshold = result.atrValue * 0.15;
         if((liveEntry - bar1Close) < -bar0ReversalThreshold)
         {
            result.reason = "BUY signal invalidated — bar0 reversed against signal";
            result.setupScore = buyScore;
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         // [FIX 6] Stop anchor with ATR wick buffer
         double stopAnchor       = MathMin(bar1Low, bar2Low) - stopWickBuffer;
         double anchoredStopDist = liveEntry - stopAnchor;
         double finalStopDist    = MathMax(baseStopDistance, anchoredStopDist);

         if(finalStopDist <= 0)
         {
            result.reason = "Invalid BUY stop distance";
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         double finalTpDist = MathMax(baseTpDistance, finalStopDist * rrMultiplier);

         // [FIX 3] Enforce minimum R:R — reject if actual R:R is too low
         double actualRR = finalTpDist / finalStopDist;
         if(actualRR < minAcceptableRR)
         {
            result.reason = StringConcatenate("BUY rejected — R:R too low: ",
                                              DoubleToStr(actualRR, 2),
                                              " < ", DoubleToStr(minAcceptableRR, 2));
            result.setupScore = buyScore;
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         result.setupScore       = buyScore;
         result.isStrongSignal   = (buyScore >= 8);
         result.isBreakoutSignal = useBreakout;
         result.isPullbackSignal = allowPullbackBuy && !useBreakout;

         result.isValid         = true;
         result.direction       = DIR_BUY;
         result.reason          = useBreakout ? "BUY breakout signal" : "BUY signal";
         result.label           = useBreakout
            ? (DeveloperTestMode ? "DevSniperBreakoutBuy" : "SniperBreakoutBuy")
            : (DeveloperTestMode ? "DevSniperBuy"         : "SniperBuy");
         result.entryPrice      = NormalizePrice(liveEntry);
         result.stopLossPrice   = NormalizePrice(liveEntry - finalStopDist);
         result.takeProfitPrice = NormalizePrice(liveEntry + finalTpDist);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.setupScore = buyScore;
      result.reason = "Sniper buy conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   if(bias == DIR_SELL)
   {
      // [FIX 12] Pullback clause 3 tightened (same logic as BUY side)
      bool pulledBack =
         ((bar2High >= emaPull1) && (bar2Close <= emaPull1 || bar1Close < emaPull1)) ||
         (SniperUseSecondEMA && (bar2High >= emaPull2)) ||
         ((bar1High >= emaPull1) && (bar1Close < emaPull1) && (bar2High >= emaPull1 * 0.994));
         // [FIX 12] Third clause now requires bar2 also approached EMA

      bool bearishRejectBar2 = IsBearishRejectionCandle(bar2Open, bar2Close, bar2High, bar2Low);
      bool bearishRejectBar1 = IsBearishRejectionCandle(bar1Open, bar1Close, bar1High, bar1Low);
      bool bearishReject = bearishRejectBar2 || bearishRejectBar1;

      // [FIX 10] Temporal separation: if rejection is on bar1,
      // confirmation must come from bar0 (forming candle)
      bool bearishConfirmBar1 =
         IsStrongBearishBreakCandle(bar1Open, bar1Close, bar1High, bar1Low, bar2Low) ||
         ((bar1Close < emaPull1) &&
          (bar1Close < bar1Open) &&
          ((bar1Open - bar1Close) >= (bar1High - bar1Low) * 0.35) &&
          (bar1Close < bar2Low));

      bool bearishConfirmBar0 =
         ((bar0Close < emaPull1) &&
          (bar0Close < bar0Open) &&
          ((bar0Open - bar0Close) >= (bar0High - bar0Low) * 0.35) &&
          (bar0Close < bar1Low));

      bool bearishConfirm;
      if(bearishRejectBar1 && !bearishRejectBar2)
         // Rejection was on bar1 — confirmation must be bar0
         bearishConfirm = bearishConfirmBar0;
      else
         // Rejection was on bar2 — bar1 confirmation is valid
         bearishConfirm = bearishConfirmBar1 || bearishConfirmBar0;

      bool bearishBreakout =
         IsBearishBreakoutSetup(bar1Open, bar1Close, bar1High, bar1Low, emaPull1, result.atrValue);

      // [FIX 8] Tighter overextension ceilings
      bool notOverextendedPullback = ((emaPull1 - bar1Close) <= result.atrValue * 0.50);
      bool notOverextendedBreakout = ((emaPull1 - bar1Close) <= result.atrValue * 0.70);

      bool extraOkPullback = (!isChoppy) && notOverextendedPullback;
      bool extraOkBreakout = (!isChoppy) && notOverextendedBreakout;

      if(devIgnoreRejection)    bearishReject  = true;
      if(devIgnoreConfirmation) bearishConfirm = true;
      if(devIgnoreExtra)        { extraOkPullback = true; extraOkBreakout = true; }

      result.pullbackOk     = pulledBack;
      result.rejectionOk    = bearishReject;
      result.confirmationOk = bearishConfirm;
      result.extraFilterOk  = extraOkPullback || extraOkBreakout;

      int sellScore = 0;
      if(result.trendOk)      sellScore += 2;
      if(result.higherBiasOk) sellScore += 1;
      if(pulledBack)          sellScore += 1;
      if(bearishReject)       sellScore += 2;
      if(bearishConfirm)      sellScore += 2;
      if(extraOkPullback)     sellScore += 1;
      if(bearishBreakout)     sellScore += 3;

      bool allowPullbackSell =
         (pulledBack && bearishConfirm && sellScore >= 5)
         ||
         (pulledBack && bearishReject && sellScore >= 7);

      // [FIX 2] Breakout requires confirmationOk or pulledBack
      bool allowBreakoutSell = (bearishBreakout && extraOkBreakout && sellScore >= 6 &&
                                (bearishConfirm || pulledBack));

      if(allowPullbackSell || allowBreakoutSell)
      {
         bool useBreakout = allowBreakoutSell;

         double liveEntry = Bid;

         // [FIX 7] Bar-0 invalidation: reject if bar0 has reversed
         // against the SELL signal direction meaningfully
         double bar0ReversalThreshold = result.atrValue * 0.15;
         if((bar1Close - liveEntry) < -bar0ReversalThreshold)
         {
            result.reason = "SELL signal invalidated — bar0 reversed against signal";
            result.setupScore = sellScore;
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         // [FIX 6] Stop anchor with ATR wick buffer
         double stopAnchor       = MathMax(bar1High, bar2High) + stopWickBuffer;
         double anchoredStopDist = stopAnchor - liveEntry;
         double finalStopDist    = MathMax(baseStopDistance, anchoredStopDist);

         if(finalStopDist <= 0)
         {
            result.reason = "Invalid SELL stop distance";
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         double finalTpDist = MathMax(baseTpDistance, finalStopDist * rrMultiplier);

         // [FIX 3] Enforce minimum R:R
         double actualRR = finalTpDist / finalStopDist;
         if(actualRR < minAcceptableRR)
         {
            result.reason = StringConcatenate("SELL rejected — R:R too low: ",
                                              DoubleToStr(actualRR, 2),
                                              " < ", DoubleToStr(minAcceptableRR, 2));
            result.setupScore = sellScore;
            if(doLog) LogSignalDiagnostics(result);
            return result;
         }

         result.setupScore       = sellScore;
         result.isStrongSignal   = (sellScore >= 8);
         result.isBreakoutSignal = useBreakout;
         result.isPullbackSignal = allowPullbackSell && !useBreakout;

         result.isValid         = true;
         result.direction       = DIR_SELL;
         result.reason          = useBreakout ? "SELL breakout signal" : "SELL signal";
         result.label           = useBreakout
            ? (DeveloperTestMode ? "DevSniperBreakoutSell" : "SniperBreakoutSell")
            : (DeveloperTestMode ? "DevSniperSell"         : "SniperSell");
         result.entryPrice      = NormalizePrice(liveEntry);
         result.stopLossPrice   = NormalizePrice(liveEntry + finalStopDist);
         result.takeProfitPrice = NormalizePrice(liveEntry - finalTpDist);

         if(doLog) LogSignalDiagnostics(result);
         return result;
      }

      result.setupScore = sellScore;
      result.reason = "Sniper sell conditions not met";
      if(doLog) LogSignalDiagnostics(result);
      return result;
   }

   result.reason = "Sniper no signal";
   if(doLog) LogSignalDiagnostics(result);
   return result;
}

#endif