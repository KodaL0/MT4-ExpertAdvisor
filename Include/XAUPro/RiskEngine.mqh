#ifndef __XAU_RISKENGINE_MQH__
#define __XAU_RISKENGINE_MQH__

double NormalizeLot(double lot)
{
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

   if(lotStep <= 0)
      lotStep = 0.01;

   lot = MathMax(minLot, MathMin(maxLot, lot));
   lot = MathFloor(lot / lotStep) * lotStep;

   return NormalizeDouble(lot, 2);
}

double GetMoneyRiskPerLot(double entryPrice, double stopLossPrice)
{
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);

   if(tickValue <= 0 || tickSize <= 0)
      return 0;

   double priceDistance = MathAbs(entryPrice - stopLossPrice);

   if(priceDistance <= 0)
      return 0;

   double ticks = priceDistance / tickSize;
   double moneyRiskPerLot = ticks * tickValue;

   return moneyRiskPerLot;
}

double CalculateRiskLot(double stopLossPrice, double entryPrice)
{
   if(!UseRiskPercent)
      return NormalizeLot(FixedLotSize);

   double riskMoney = AccountBalance() * (RiskPercent / 100.0);
   if(riskMoney <= 0)
      return 0;

   double moneyRiskPerLot = GetMoneyRiskPerLot(entryPrice, stopLossPrice);
   if(moneyRiskPerLot <= 0)
      return 0;

   double lot = riskMoney / moneyRiskPerLot;

   return NormalizeLot(lot);
}

bool IsStopDistanceValid(int direction, double entryPrice, double stopLossPrice, double takeProfitPrice)
{
   int stopLevelPoints = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   double minStopDistance = stopLevelPoints * Point;

   if(minStopDistance <= 0)
      return true;

   if(direction == DIR_BUY)
   {
      if((entryPrice - stopLossPrice) < minStopDistance)
         return false;
      if((takeProfitPrice - entryPrice) < minStopDistance)
         return false;
   }
   else if(direction == DIR_SELL)
   {
      if((stopLossPrice - entryPrice) < minStopDistance)
         return false;
      if((entryPrice - takeProfitPrice) < minStopDistance)
         return false;
   }

   return true;
}

#endif