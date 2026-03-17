#property strict

#include <XAUPro/Config.mqh>
#include <XAUPro/Types.mqh>
#include <XAUPro/Logger.mqh>
#include <XAUPro/Utils.mqh>
#include <XAUPro/BarDetector.mqh>
#include <XAUPro/SessionFilter.mqh>
#include <XAUPro/SymbolInfoEx.mqh>
#include <XAUPro/VolatilityFilter.mqh>
#include <XAUPro/TrendFilter.mqh>
#include <XAUPro/SignalEngine.mqh>
#include <XAUPro/RiskEngine.mqh>
#include <XAUPro/ExecutionEngine.mqh>
#include <XAUPro/TradeManager.mqh>
#include <XAUPro/DailyGuard.mqh>
#include <XAUPro/StatusPanel.mqh>
#include <XAUPro/TradeJournal.mqh>

datetime g_lastBarTime = 0;
SignalResult g_lastSignal;

int OnInit()
{
   LogInfo("XAU Pro EA V2 initialized");
   InitializeTradeHistoryTracking();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   UpdateClosedTradesStats();

   if(!IsCorrectSymbol())
      return;

   if(Period() != PERIOD_M15)
      return;

   ManageOpenPositions();

   g_lastSignal = BuildSignal(false);
   DrawStatusPanel(g_lastSignal);

   if(!IsNewBar(g_lastBarTime))
      return;

   if(!IsTradingHour())
   {
      LogSkip("Outside trading hours | Session=" + GetSessionName());
      return;
   }

   if(!IsSpreadOk())
   {
      LogSkip("Spread too high");
      return;
   }

   if(!IsVolatilityOk())
   {
      LogSkip("Volatility filter blocked trade");
      return;
   }

   if(!CanTradeToday())
   {
      LogSkip("Daily guard blocked trade");
      return;
   }

   if(CountOpenPositionsByMagic(Symbol(), MagicNumber) >= MaxOpenPositions)
   {
      LogSkip("Max open positions reached");
      return;
   }

   SignalResult signal = BuildSignal(true);
   g_lastSignal = signal;
   DrawStatusPanel(g_lastSignal);

   if(!signal.isValid)
   {
      LogSkip(signal.reason);
      return;
   }

   double lotSize = CalculateRiskLot(signal.stopLossPrice, signal.entryPrice);

   if(lotSize <= 0)
   {
      LogSkip("Calculated lot size invalid");
      return;
   }

   bool ok = ExecuteSignal(signal, lotSize);

   if(ok)
      LogTrade("Trade executed: " + signal.label);
}