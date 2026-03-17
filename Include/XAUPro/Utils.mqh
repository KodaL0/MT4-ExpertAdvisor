#ifndef __XAU_UTILS_MQH__
#define __XAU_UTILS_MQH__

double NormalizePrice(double price)
{
   return NormalizeDouble(price, Digits);
}

bool IsCorrectSymbol()
{
   if(Symbol() == "XAUUSD" || Symbol() == "GOLD")
      return true;

   if(StringFind(Symbol(), "XAUUSD", 0) == 0)
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

#endif