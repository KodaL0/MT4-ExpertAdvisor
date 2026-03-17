#ifndef __XAU_VOLFILTER_MQH__
#define __XAU_VOLFILTER_MQH__

bool IsSpreadOk()
{
   int spread = (int)((Ask - Bid) / Point);
   return (spread <= MaxSpreadPoints);
}

double GetATRValue(int shift = 1)
{
   return iATR(Symbol(), PERIOD_M15, ATRPeriod, shift);
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

   double atr = GetATRValue(1);
   if(atr <= 0)
      return false;

   double candleSize = High[1] - Low[1];
   double ratio = candleSize / atr;

   return (ratio > MaxCandleToATRRatio);
}

#endif