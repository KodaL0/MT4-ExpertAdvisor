#ifndef __XAU_SYMBOLINFOEX_MQH__
#define __XAU_SYMBOLINFOEX_MQH__

double GetSymbolPoint()
{
   return MarketInfo(Symbol(), MODE_POINT);
}

int GetSymbolDigits()
{
   return (int)MarketInfo(Symbol(), MODE_DIGITS);
}

double GetMinLot()
{
   return MarketInfo(Symbol(), MODE_MINLOT);
}

double GetMaxLot()
{
   return MarketInfo(Symbol(), MODE_MAXLOT);
}

double GetLotStep()
{
   return MarketInfo(Symbol(), MODE_LOTSTEP);
}

int GetStopLevelPoints()
{
   return (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
}

int GetFreezeLevelPoints()
{
   return (int)MarketInfo(Symbol(), MODE_FREEZELEVEL);
}

double GetTickValue()
{
   return MarketInfo(Symbol(), MODE_TICKVALUE);
}

int GetSpreadPoints()
{
   return (int)((Ask - Bid) / Point);
}

#endif