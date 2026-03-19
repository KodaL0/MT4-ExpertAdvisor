#ifndef __XAU_STATUSPANEL_MQH__
#define __XAU_STATUSPANEL_MQH__

string BoolToText(bool v)
{
   return v ? "YES" : "NO";
}

string DirectionToPanelText(int dir)
{
   if(dir == DIR_BUY) return "BUY";
   if(dir == DIR_SELL) return "SELL";
   return "NONE";
}

string TimeframeToText(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:   return "M1";
      case PERIOD_M5:   return "M5";
      case PERIOD_M15:  return "M15";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H4:   return "H4";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
   }

   return "UNKNOWN";
}

string GetDailyGuardPanelStatus()
{
   if(!UseDailyGuard)
      return "OFF";

   ResetDailyCountersIfNeeded();

   if(g_tradesToday >= MaxTradesPerDay)
      return "BLOCKED: MAX TRADES";

   if(g_consecutiveLosses >= MaxConsecutiveLosses)
      return "BLOCKED: LOSSES";

   if(UseMaxDailyLossPercent)
   {
      double dailyLossPct = GetCurrentDailyLossPercent();
      if(dailyLossPct >= MaxDailyLossPercent)
         return "BLOCKED: DAILY LOSS";
   }

   return "OK";
}

string GetCooldownPanelStatus(BotStats &stats)
{
   if(!UseTradeCooldown)
      return "OFF";

   if(stats.cooldownBarsRemaining > 0)
      return "ACTIVE";

   return "READY";
}

string GetSpreadPanelStatus(int spreadPoints)
{
   if(spreadPoints <= MaxSpreadPoints)
      return "OK";

   return "HIGH";
}

void DrawStatusPanel(SignalResult &signal)
{
   if(!ShowStatusPanel)
   {
      Comment("");
      return;
   }

   BotStats stats = GetBotStats();
   ENUM_TIMEFRAMES entryTf = GetRequiredEntryTimeframe();

   string panel =
      "XAU PRO BOT\n" +
      "Strategy: " + GetStrategyModeName() + "\n" +
      "Mode: " + string(DeveloperTestMode ? "DEV TEST" : "NORMAL") + "\n" +
      "Chart TF: " + TimeframeToText((ENUM_TIMEFRAMES)Period()) + "\n" +
      "Entry TF: " + TimeframeToText(entryTf) + "\n" +
      "Session: " + GetSessionName() + "\n" +
      "Regime: " + RegimeToText(signal.regime) + "\n" +
      "Trend: " + DirectionToPanelText(signal.direction) + "\n" +
      "Trend OK: " + BoolToText(signal.trendOk) + "\n" +
      "Higher Bias OK: " + BoolToText(signal.higherBiasOk) + "\n" +
      "ATR: " + DoubleToString(signal.atrValue, 2) + "\n" +
      "Spread: " + IntegerToString(signal.spreadPoints) + " (" + GetSpreadPanelStatus(signal.spreadPoints) + ")\n" +
      "Pullback: " + BoolToText(signal.pullbackOk) + "\n" +
      "Rejection: " + BoolToText(signal.rejectionOk) + "\n" +
      "Confirm: " + BoolToText(signal.confirmationOk) + "\n" +
      "Extra: " + BoolToText(signal.extraFilterOk) + "\n" +
      "Signal Valid: " + BoolToText(signal.isValid) + "\n" +
      "SL: " + DoubleToString(signal.stopLossPrice, Digits) + "\n" +
      "TP: " + DoubleToString(signal.takeProfitPrice, Digits) + "\n" +
      "Reason: " + signal.reason + "\n" +
      "Daily Guard: " + GetDailyGuardPanelStatus() + "\n" +
      "Cooldown: " + GetCooldownPanelStatus(stats) + "\n" +
      "Cooldown Bars: " + IntegerToString(stats.cooldownBarsRemaining) + "\n" +
      "Open Positions: " + IntegerToString(stats.openPositions) + "/" + IntegerToString(MaxOpenPositions) + "\n" +
      "Trades Today: " + IntegerToString(stats.tradesToday) + "\n" +
      "Wins Today: " + IntegerToString(stats.winsToday) + "\n" +
      "Losses Today: " + IntegerToString(stats.lossesToday) + "\n" +
      "Consec Losses: " + IntegerToString(stats.consecutiveLosses) + "\n" +
      "Daily PnL: " + DoubleToString(stats.dailyClosedPnL, 2) + "\n" +
      "Daily Loss %: " + DoubleToString(GetCurrentDailyLossPercent(), 2);

   Comment(panel);
}

#endif