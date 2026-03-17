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

void DrawStatusPanel(SignalResult &signal)
{
   if(!ShowStatusPanel)
   {
      Comment("");
      return;
   }

   BotStats stats = GetBotStats();

   string panel =
      "XAU PRO BOT\n" +
      "Mode: " + string(DeveloperTestMode ? "DEV TEST" : "NORMAL") + "\n" +
      "Trend: " + DirectionToPanelText(signal.direction) + "\n" +
      "ATR: " + DoubleToString(signal.atrValue, 2) + "\n" +
      "Spread: " + IntegerToString(signal.spreadPoints) + "\n" +
      "Trend OK: " + BoolToText(signal.trendOk) + "\n" +
      "Pullback: " + BoolToText(signal.pullbackOk) + "\n" +
      "Rejection: " + BoolToText(signal.rejectionOk) + "\n" +
      "Confirm: " + BoolToText(signal.confirmationOk) + "\n" +
      "Extra: " + BoolToText(signal.extraFilterOk) + "\n" +
      "Signal Valid: " + BoolToText(signal.isValid) + "\n" +
      "SL: " + DoubleToString(signal.stopLossPrice, Digits) + "\n" +
      "TP: " + DoubleToString(signal.takeProfitPrice, Digits) + "\n" +
      "Reason: " + signal.reason + "\n" +
      "Session: " + GetSessionName() + "\n" +
      "Daily Guard: " + string(CanTradeToday() ? "OK" : "BLOCKED") + "\n" +
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