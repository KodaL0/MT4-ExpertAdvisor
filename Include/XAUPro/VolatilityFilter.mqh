#ifndef __XAU_VOLFILTER_MQH__
#define __XAU_VOLFILTER_MQH__

bool IsSpreadOk()
{
   int spread = (int)((Ask - Bid) / Point);
   return (spread <= MaxSpreadPoints);
}

double GetATRValue(int shift = 1)
{
   return iATR(Symbol(), GetSignalATRTimeframe(), ATRPeriod, shift);
}

bool IsVolatilityOk()
{
   double atr = GetATRValue(1);

   if(atr < MinATR)
      return false;

   if(atr > MaxATR)
      return false;

   return true;
}

bool IsAbnormalCandle()
{
   if(!UseAbnormalCandleFilter)
      return false;

   ENUM_TIMEFRAMES tf = GetSignalATRTimeframe();

   double atr = GetATRValue(1);
   if(atr <= 0)
      return false;

   double candleHigh = iHigh(Symbol(), tf, 1);
   double candleLow  = iLow(Symbol(), tf, 1);
   double candleSize = candleHigh - candleLow;

   if(candleSize <= 0)
      return false;

   double ratio = candleSize / atr;

   return (ratio > MaxCandleToATRRatio);
}

#endif