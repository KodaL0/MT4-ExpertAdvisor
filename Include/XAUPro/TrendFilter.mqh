#ifndef __XAU_TRENDFILTER_MQH__
#define __XAU_TRENDFILTER_MQH__

int GetTrendDirection()
{
   double fast = iMA(Symbol(), TrendTimeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slow = iMA(Symbol(), TrendTimeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);

   if(fast > slow) return DIR_BUY;
   if(fast < slow) return DIR_SELL;
   return DIR_NONE;
}

bool IsTrendStrongEnough()
{
   if(!UseEMASeparationFilter)
      return true;

   double fast = iMA(Symbol(), TrendTimeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slow = iMA(Symbol(), TrendTimeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);

   double separationPoints = MathAbs(fast - slow) / Point;

   return (separationPoints >= MinEMASeparationPoints);
}

#endif