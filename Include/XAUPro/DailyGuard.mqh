#ifndef __XAU_DAILYGUARD_MQH__
#define __XAU_DAILYGUARD_MQH__

int g_tradesToday = 0;
int g_consecutiveLosses = 0;
int g_winsToday = 0;
int g_lossesToday = 0;
datetime g_lastTradeDay = 0;
double g_dailyClosedPnL = 0.0;
double g_dayStartBalance = 0.0;

datetime g_lastTradeBarTime = 0;
bool g_lastClosedTradeWasLoss = false;

datetime GetCurrentStrategyBarTime()
{
   ENUM_TIMEFRAMES tf = GetRequiredEntryTimeframe();
   return iTime(Symbol(), tf, 0);
}

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
      g_lastClosedTradeWasLoss = false;
      g_lastTradeBarTime = 0;

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

int GetBarsSinceLastTrade()
{
   if(g_lastTradeBarTime == 0)
      return 9999;

   ENUM_TIMEFRAMES tf = GetRequiredEntryTimeframe();
   int shift = iBarShift(Symbol(), tf, g_lastTradeBarTime, false);

   if(shift < 0)
      return 9999;

   return shift;
}

int GetRequiredCooldownBars()
{
   if(!UseTradeCooldown)
      return 0;

   if(g_lastClosedTradeWasLoss)
      return CooldownBarsAfterLoss;

   return CooldownBarsAfterTrade;
}

int GetCooldownBarsRemaining()
{
   if(!UseTradeCooldown)
      return 0;

   int requiredBars = GetRequiredCooldownBars();
   int barsSinceTrade = GetBarsSinceLastTrade();

   int remaining = requiredBars - barsSinceTrade;
   if(remaining < 0)
      remaining = 0;

   return remaining;
}

bool IsCooldownActive()
{
   if(!UseTradeCooldown)
      return false;

   return GetCooldownBarsRemaining() > 0;
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
   g_lastTradeBarTime = GetCurrentStrategyBarTime();
}

void RegisterTradeResult(double profit)
{
   ResetDailyCountersIfNeeded();

   g_dailyClosedPnL += profit;
   g_lastClosedTradeWasLoss = (profit < 0);

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
   s.cooldownBarsRemaining = GetCooldownBarsRemaining();
   return s;
}

#endif