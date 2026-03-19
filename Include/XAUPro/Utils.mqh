#ifndef __XAU_UTILS_MQH__
#define __XAU_UTILS_MQH__

double NormalizePrice(double price)
{
   return NormalizeDouble(price, Digits);
}

bool IsCorrectSymbol()
{
   string sym = Symbol();
   StringToUpper(sym);

   if(sym == "XAUUSD" || sym == "GOLD")
      return true;

   if(StringFind(sym, "XAUUSD", 0) == 0)
      return true;

   return false;
}

int CountOpenPositionsByMagic(string symbol, int magic)
{
   int count = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == symbol && OrderMagicNumber() == magic)
            count++;
      }
   }

   return count;
}

bool HasOpenPositionByMagic(string symbol, int magic)
{
   return CountOpenPositionsByMagic(symbol, magic) > 0;
}

ENUM_TIMEFRAMES GetRequiredEntryTimeframe()
{
   if(StrategyMode == 2)
      return PERIOD_M5;

   return PERIOD_M15;
}

ENUM_TIMEFRAMES GetSignalATRTimeframe()
{
   return GetRequiredEntryTimeframe();
}

ENUM_TIMEFRAMES GetManagementATRTimeframe()
{
   return GetRequiredEntryTimeframe();
}

string GetStrategyModeName()
{
   if(StrategyMode == 2)
      return "SNIPER";

   return "TREND_PRO";
}

bool IsStrategyChartTimeframe()
{
   return Period() == GetRequiredEntryTimeframe();
}

#endif