#ifndef __XAU_TRENDFILTER_MQH__
#define __XAU_TRENDFILTER_MQH__

int GetTrendDirectionForTimeframe(ENUM_TIMEFRAMES tf, int fastPeriod = -1, int slowPeriod = -1)
{
   if(fastPeriod <= 0)
      fastPeriod = FastEMA;

   if(slowPeriod <= 0)
      slowPeriod = SlowEMA;

   double fast = iMA(Symbol(), tf, fastPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slow = iMA(Symbol(), tf, slowPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);

   if(fast > slow) return DIR_BUY;
   if(fast < slow) return DIR_SELL;
   return DIR_NONE;
}

int GetTrendDirection()
{
   return GetTrendDirectionForTimeframe(TrendTimeframe, FastEMA, SlowEMA);
}

int GetHigherBiasDirection()
{
   return GetTrendDirectionForTimeframe(HigherBiasTimeframe, FastEMA, SlowEMA);
}

int GetSniperBiasDirection()
{
   return GetTrendDirectionForTimeframe(SniperBiasTimeframe, SniperFastEMA, SniperSlowEMA);
}

bool IsMultiTimeframeBiasAligned()
{
   if(!UseMultiTimeframeBias)
      return true;

   int trendDir = GetTrendDirectionForTimeframe(TrendTimeframe, FastEMA, SlowEMA);
   int higherDir = GetTrendDirectionForTimeframe(HigherBiasTimeframe, FastEMA, SlowEMA);

   if(trendDir == DIR_NONE || higherDir == DIR_NONE)
      return false;

   return trendDir == higherDir;
}

bool IsTrendStrongEnoughForTimeframe(ENUM_TIMEFRAMES tf, double minSeparationPoints, int fastPeriod = -1, int slowPeriod = -1)
{
   if(fastPeriod <= 0)
      fastPeriod = FastEMA;

   if(slowPeriod <= 0)
      slowPeriod = SlowEMA;

   double fast = iMA(Symbol(), tf, fastPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slow = iMA(Symbol(), tf, slowPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);

   double separationPoints = MathAbs(fast - slow) / Point;

   return (separationPoints >= minSeparationPoints);
}

bool IsTrendStrongEnough()
{
   if(!UseEMASeparationFilter)
      return true;

   return IsTrendStrongEnoughForTimeframe(TrendTimeframe, MinEMASeparationPoints, FastEMA, SlowEMA);
}

#endif