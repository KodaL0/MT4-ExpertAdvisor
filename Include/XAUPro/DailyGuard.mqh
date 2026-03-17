#ifndef __XAU_DAILYGUARD_MQH__
#define __XAU_DAILYGUARD_MQH__

int g_tradesToday = 0;
int g_consecutiveLosses = 0;
int g_winsToday = 0;
int g_lossesToday = 0;
datetime g_lastTradeDay = 0;
double g_dailyClosedPnL = 0.0;
double g_dayStartBalance = 0.0;

void ResetDailyCountersIfNeeded()
{
   datetime now = TimeCurrent();

   if(g_lastTradeDay == 0)
   {
      g_lastTradeDay = now;
      g_dayStartBalance = AccountBalance();
      return;
   }

   bool newDay =
      TimeYear(now)  != TimeYear(g_lastTradeDay) ||
      TimeMonth(now) != TimeMonth(g_lastTradeDay) ||
      TimeDay(now)   != TimeDay(g_lastTradeDay);

   if(newDay)
   {
      g_tradesToday = 0;
      g_consecutiveLosses = 0;
      g_winsToday = 0;
      g_lossesToday = 0;
      g_dailyClosedPnL = 0.0;
      g_lastTradeDay = now;
      g_dayStartBalance = AccountBalance();

      LogInfo("Daily counters reset");
   }
}

double GetCurrentDailyLossPercent()
{
   if(g_dayStartBalance <= 0)
      return 0.0;

   if(g_dailyClosedPnL >= 0)
      return 0.0;

   return MathAbs(g_dailyClosedPnL) / g_dayStartBalance * 100.0;
}

bool CanTradeToday()
{
   if(!UseDailyGuard)
      return true;

   ResetDailyCountersIfNeeded();

   if(g_tradesToday >= MaxTradesPerDay)
   {
      LogSkip("Max trades per day reached");
      return false;
   }

   if(g_consecutiveLosses >= MaxConsecutiveLosses)
   {
      LogSkip("Max consecutive losses reached");
      return false;
   }

   if(UseMaxDailyLossPercent)
   {
      double dailyLossPct = GetCurrentDailyLossPercent();
      if(dailyLossPct >= MaxDailyLossPercent)
      {
         LogSkip("Max daily loss % reached");
         return false;
      }
   }

   return true;
}

void RegisterTrade()
{
   ResetDailyCountersIfNeeded();
   g_tradesToday++;
   g_lastTradeDay = TimeCurrent();
}

void RegisterTradeResult(double profit)
{
   ResetDailyCountersIfNeeded();

   g_dailyClosedPnL += profit;

   if(profit < 0)
   {
      g_consecutiveLosses++;
      g_lossesToday++;
   }
   else
   {
      g_consecutiveLosses = 0;
      g_winsToday++;
   }
}

BotStats GetBotStats()
{
   ResetDailyCountersIfNeeded();

   BotStats s;
   s.tradesToday = g_tradesToday;
   s.winsToday = g_winsToday;
   s.lossesToday = g_lossesToday;
   s.consecutiveLosses = g_consecutiveLosses;
   s.openPositions = CountOpenPositionsByMagic(Symbol(), MagicNumber);
   s.dailyClosedPnL = g_dailyClosedPnL;
   return s;
}

#endif