#ifndef __XAU_REGIMEFILTER_MQH__
#define __XAU_REGIMEFILTER_MQH__

string RegimeToText(int regime)
{
   if(regime == REGIME_TRENDING) return "TRENDING";
   if(regime == REGIME_RANGING)  return "RANGING";
   if(regime == REGIME_CHAOTIC)  return "CHAOTIC";
   if(regime == REGIME_DEAD)     return "DEAD";
   return "UNKNOWN";
}

double GetRegimeATR()
{
   return iATR(Symbol(), PERIOD_M15, ATRPeriod, 1);
}

double GetRegimeEMASeparationPoints()
{
   double fast = iMA(Symbol(), TrendTimeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slow = iMA(Symbol(), TrendTimeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   return MathAbs(fast - slow) / Point;
}

double GetPrevCandleToATRRatio()
{
   double atr = GetRegimeATR();
   if(atr <= 0)
      return 0.0;

   double candleSize = High[1] - Low[1];
   return candleSize / atr;
}

int DetectMarketRegime()
{
   double atr = GetRegimeATR();
   double emaSep = GetRegimeEMASeparationPoints();
   double candleAtrRatio = GetPrevCandleToATRRatio();

   if(atr < RegimeMinATR)
      return REGIME_DEAD;

   if(candleAtrRatio >= RegimeChaoticCandleATRRatio || atr > RegimeMaxATR)
      return REGIME_CHAOTIC;

   if(emaSep >= RegimeMinEMASeparationPoints)
      return REGIME_TRENDING;

   return REGIME_RANGING;
}

bool IsTradableRegime()
{
   if(!UseRegimeFilter)
      return true;

   int regime = DetectMarketRegime();
   return regime == REGIME_TRENDING;
}

#endif