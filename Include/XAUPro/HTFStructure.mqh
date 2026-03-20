#ifndef __XAU_HTFSTRUCTURE_MQH__
#define __XAU_HTFSTRUCTURE_MQH__

// ============================================================
// HTFStructure.mqh
// Higher-Timeframe Swing High / Low Structure Awareness
//
// What this does:
//   Scans H1 and H4 bars to find the most recent meaningful
//   swing high and swing low. Then checks whether the current
//   entry is positioned sensibly relative to those levels:
//
//   BUY  — is price far enough from a major H1/H4 resistance?
//          A buy signal 5 pips below a H4 swing high is low
//          quality. A buy signal in open air above broken
//          structure is high quality.
//
//   SELL — is price far enough from a major H1/H4 support?
//          Same logic inverted.
//
//   The result is exposed as:
//     result.htfStructureOk   — bool gate (pass/fail)
//     result.htfSwingHigh     — nearest H1/H4 swing high price
//     result.htfSwingLow      — nearest H1/H4 swing low price
//     result.htfBiasScore     — 0/1/2 bonus added to setupScore
//
// Config inputs (add to Config.mqh):
//   UseHTFStructureFilter     — master on/off
//   HTFStructureTimeframe     — H1 (60) or H4 (240)
//   HTFSwingLookback          — how many bars to scan (default 40)
//   HTFStructureBufferATR     — minimum distance from structure
//                               as ATR multiplier (default 0.30)
// ============================================================

// -------------------------------------------------------
// Internal: find the highest high over a bar range
// -------------------------------------------------------
double FindSwingHigh(ENUM_TIMEFRAMES tf, int startShift, int barsCount)
{
   double highest = iHigh(Symbol(), tf, startShift);
   for(int i = startShift + 1; i < startShift + barsCount; i++)
   {
      double h = iHigh(Symbol(), tf, i);
      if(h > highest) highest = h;
   }
   return highest;
}

// -------------------------------------------------------
// Internal: find the lowest low over a bar range
// -------------------------------------------------------
double FindSwingLow(ENUM_TIMEFRAMES tf, int startShift, int barsCount)
{
   double lowest = iLow(Symbol(), tf, startShift);
   for(int i = startShift + 1; i < startShift + barsCount; i++)
   {
      double l = iLow(Symbol(), tf, i);
      if(l < lowest) lowest = l;
   }
   return lowest;
}

// -------------------------------------------------------
// Internal: find a proper swing high — a bar whose high
// is higher than N bars on each side (pivot detection)
// Returns price of the swing high, or 0 if none found
// -------------------------------------------------------
double FindPivotHigh(ENUM_TIMEFRAMES tf, int lookback, int pivotStrength = 3)
{
   for(int i = pivotStrength + 1; i < lookback; i++)
   {
      double centerHigh = iHigh(Symbol(), tf, i);
      bool isPivot = true;

      for(int j = 1; j <= pivotStrength; j++)
      {
         if(iHigh(Symbol(), tf, i - j) >= centerHigh) { isPivot = false; break; }
         if(iHigh(Symbol(), tf, i + j) >= centerHigh) { isPivot = false; break; }
      }

      if(isPivot) return centerHigh;
   }
   return 0;
}

// -------------------------------------------------------
// Internal: find a proper swing low — pivot detection
// Returns price of the swing low, or 0 if none found
// -------------------------------------------------------
double FindPivotLow(ENUM_TIMEFRAMES tf, int lookback, int pivotStrength = 3)
{
   for(int i = pivotStrength + 1; i < lookback; i++)
   {
      double centerLow = iLow(Symbol(), tf, i);
      bool isPivot = true;

      for(int j = 1; j <= pivotStrength; j++)
      {
         if(iLow(Symbol(), tf, i - j) <= centerLow) { isPivot = false; break; }
         if(iLow(Symbol(), tf, i + j) <= centerLow) { isPivot = false; break; }
      }

      if(isPivot) return centerLow;
   }
   return 0;
}

// -------------------------------------------------------
// Main structure result struct
// -------------------------------------------------------
struct HTFStructureResult
{
   double swingHigh;        // nearest meaningful HTF swing high
   double swingLow;         // nearest meaningful HTF swing low
   double distanceToHigh;   // distance from current price to swing high (points)
   double distanceToLow;    // distance from current price to swing low (points)
   bool   priceNearHigh;    // true if price is dangerously close to swing high
   bool   priceNearLow;     // true if price is dangerously close to swing low
   bool   buyStructureOk;   // true if BUY entry has room before next resistance
   bool   sellStructureOk;  // true if SELL entry has room before next support
   int    biasScore;        // 0 = neutral/blocked, 1 = ok, 2 = strong (in open air)
   string reason;
};

// -------------------------------------------------------
// Core function: evaluate HTF structure for current price
// Call this from SignalEngineSniper before finalising signal
// -------------------------------------------------------
HTFStructureResult EvaluateHTFStructure(double currentPrice, double atrValue)
{
   HTFStructureResult res;
   res.swingHigh       = 0;
   res.swingLow        = 0;
   res.distanceToHigh  = 0;
   res.distanceToLow   = 0;
   res.priceNearHigh   = false;
   res.priceNearLow    = false;
   res.buyStructureOk  = true;
   res.sellStructureOk = true;
   res.biasScore       = 1;
   res.reason          = "HTF structure OK";

   if(!UseHTFStructureFilter)
   {
      res.biasScore = 1;
      res.reason    = "HTF structure filter disabled";
      return res;
   }

   if(atrValue <= 0)
   {
      res.reason = "HTF structure: invalid ATR";
      return res;
   }

   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)HTFStructureTimeframe;

   // Find nearest pivot swing high and low on the HTF
   double pivotHigh = FindPivotHigh(tf, HTFSwingLookback, 3);
   double pivotLow  = FindPivotLow(tf, HTFSwingLookback, 3);

   // Fallback to simple range high/low if no clean pivot found
   if(pivotHigh <= 0) pivotHigh = FindSwingHigh(tf, 1, HTFSwingLookback);
   if(pivotLow  <= 0) pivotLow  = FindSwingLow(tf, 1, HTFSwingLookback);

   res.swingHigh = pivotHigh;
   res.swingLow  = pivotLow;

   // Minimum buffer required between entry and structure level
   // expressed as ATR multiple — default 0.30x ATR
   double requiredBuffer = atrValue * HTFStructureBufferATR;

   if(pivotHigh > 0)
   {
      res.distanceToHigh = (pivotHigh - currentPrice) / Point;
      double bufferPoints = requiredBuffer / Point;

      // Price is too close to a HTF swing high — risky for BUY
      if(currentPrice >= pivotHigh - requiredBuffer)
      {
         res.priceNearHigh  = true;
         res.buyStructureOk = false;
      }
   }

   if(pivotLow > 0)
   {
      res.distanceToLow = (currentPrice - pivotLow) / Point;
      double bufferPoints = requiredBuffer / Point;

      // Price is too close to a HTF swing low — risky for SELL
      if(currentPrice <= pivotLow + requiredBuffer)
      {
         res.priceNearLow    = true;
         res.sellStructureOk = false;
      }
   }

   // Score the structure quality:
   //   2 = price is well clear of structure (> 2x buffer) — strong setup
   //   1 = price has acceptable clearance (1-2x buffer) — ok setup
   //   0 = price is at or near structure — blocked
   double twoXBuffer = requiredBuffer * 2.0;

   bool buyBlocked  = !res.buyStructureOk;
   bool sellBlocked = !res.sellStructureOk;

   if(!buyBlocked && !sellBlocked)
   {
      // Check if well clear on both sides
      bool wellClearHigh = (pivotHigh <= 0 || (pivotHigh - currentPrice) >= twoXBuffer);
      bool wellClearLow  = (pivotLow  <= 0 || (currentPrice - pivotLow)  >= twoXBuffer);

      if(wellClearHigh && wellClearLow)
      {
         res.biasScore = 2;
         res.reason    = "HTF structure: price in open air — strong";
      }
      else
      {
         res.biasScore = 1;
         res.reason    = "HTF structure: acceptable clearance";
      }
   }
   else
   {
      res.biasScore = 0;
      if(res.priceNearHigh && res.priceNearLow)
         res.reason = "HTF structure: price compressed between swing levels";
      else if(res.priceNearHigh)
         res.reason = "HTF structure: price near swing high — BUY blocked";
      else
         res.reason = "HTF structure: price near swing low — SELL blocked";
   }

   return res;
}

// -------------------------------------------------------
// Convenience wrappers called from SignalEngineSniper
// -------------------------------------------------------
bool IsHTFStructureOkForBuy(HTFStructureResult &htf)
{
   if(!UseHTFStructureFilter) return true;
   return htf.buyStructureOk;
}

bool IsHTFStructureOkForSell(HTFStructureResult &htf)
{
   if(!UseHTFStructureFilter) return true;
   return htf.sellStructureOk;
}

#endif