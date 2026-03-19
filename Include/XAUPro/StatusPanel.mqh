#ifndef __XAU_STATUSPANEL_MQH__
#define __XAU_STATUSPANEL_MQH__

#define PANEL_PREFIX "XAU_PRO_PANEL_"

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

string ToUpperText(string s)
{
   StringToUpper(s);
   return s;
}

string InferProfileLabel()
{
   string upperCsv = ToUpperText(CSVFileName);

   if(StringFind(upperCsv, "TEST", 0) >= 0)   return "TEST";
   if(StringFind(upperCsv, "NORMAL", 0) >= 0) return "NORMAL";
   if(StringFind(upperCsv, "LIVE", 0) >= 0)   return "LIVE";
   if(StringFind(upperCsv, "DEMO", 0) >= 0)   return "DEMO";

   if(DeveloperTestMode)
      return "DEV";

   return "LIVE";
}

string GetSignalStateText(SignalResult &signal)
{
   if(signal.isStrongSignal && signal.isValid)
      return "STRONG SIGNAL";

   if(signal.isValid)
      return "ENTRY READY";

   if(signal.setupScore >= 4)
      return "SETUP BUILDING";

   return "NO SIGNAL";
}

color GetSignalStateColor(SignalResult &signal)
{
   if(signal.isStrongSignal && signal.isValid) return clrGold;
   if(signal.isValid) return clrLimeGreen;
   if(signal.setupScore >= 4) return clrOrange;
   return clrSilver;
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

string GetSetupTypeText(SignalResult &signal)
{
   if(signal.isBreakoutSignal) return "BREAKOUT";
   if(signal.isPullbackSignal) return "PULLBACK";
   return "NONE";
}

color GetBoolColor(bool v)
{
   return v ? clrLimeGreen : clrTomato;
}

color GetDirectionColor(int dir)
{
   if(dir == DIR_BUY)  return clrLimeGreen;
   if(dir == DIR_SELL) return clrTomato;
   return clrSilver;
}

color GetSpreadStatusColor(int spreadPoints)
{
   return (spreadPoints <= MaxSpreadPoints) ? clrLimeGreen : clrOrangeRed;
}

color GetGuardStatusColor(string status)
{
   if(status == "OK") return clrLimeGreen;
   if(status == "OFF") return clrSilver;
   return clrOrangeRed;
}

color GetCooldownStatusColor(string status)
{
   if(status == "READY") return clrLimeGreen;
   if(status == "OFF") return clrSilver;
   return clrOrange;
}

color GetScoreColor(int score)
{
   if(score >= 8) return clrLimeGreen;
   if(score >= 5) return clrGold;
   if(score >= 3) return clrOrange;
   return clrTomato;
}

color GetPnLColor(double pnl)
{
   if(pnl > 0) return clrLimeGreen;
   if(pnl < 0) return clrTomato;
   return clrSilver;
}

void DeleteStatusPanelObjects()
{
   ObjectDelete(0, PANEL_PREFIX + "BG");
   ObjectDelete(0, PANEL_PREFIX + "HEADER");
   ObjectDelete(0, PANEL_PREFIX + "SIGNALBAR");
   ObjectDelete(0, PANEL_PREFIX + "TITLE");
   ObjectDelete(0, PANEL_PREFIX + "SUBTITLE");
   ObjectDelete(0, PANEL_PREFIX + "STATE");

   for(int i = 0; i < 140; i++)
   {
      ObjectDelete(0, PANEL_PREFIX + "LINE_" + IntegerToString(i) + "_L");
      ObjectDelete(0, PANEL_PREFIX + "LINE_" + IntegerToString(i) + "_R");
   }
}

bool EnsureRectangleLabel(string name, int corner, int x, int y, int w, int h, color bgColor, color borderColor)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_COLOR, borderColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}

bool EnsureLabel(string name, int corner, int x, int y, string text, color textColor, int fontSize, string fontName = "Lucida Console")
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, fontName);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}

string TrimToWidth(string txt, int maxChars)
{
   if(maxChars < 4)
      return txt;

   if(StringLen(txt) <= maxChars)
      return txt;

   return StringSubstr(txt, 0, maxChars - 3) + "...";
}

void SplitReasonText(string reason, int maxCharsPerLine, string &line1, string &line2)
{
   string clean = reason;
   line1 = "";
   line2 = "";

   if(StringLen(clean) <= maxCharsPerLine)
   {
      line1 = clean;
      return;
   }

   int splitPos = maxCharsPerLine;
   line1 = TrimToWidth(StringSubstr(clean, 0, splitPos), maxCharsPerLine);
   line2 = TrimToWidth(StringSubstr(clean, splitPos), maxCharsPerLine);
}

void DrawPanelLine(int &row, int corner, int baseX, int baseY, int leftColX, int rightColX,
                   string leftText, string rightText, color leftColor, color rightColor,
                   bool header, int panelWidth)
{
   int rowHeight = 18;
   int y = baseY + row * rowHeight;
   int leftX = baseX + leftColX;
   int rightX = baseX + rightColX;

   int leftSize = header ? 10 : 9;
   int rightSize = header ? 10 : 9;

   string shownLeft = TrimToWidth(leftText, 18);
   string shownRight = TrimToWidth(rightText, 16);

   EnsureLabel(PANEL_PREFIX + "LINE_" + IntegerToString(row) + "_L", corner, leftX, y, shownLeft, leftColor, leftSize, "Lucida Console");
   EnsureLabel(PANEL_PREFIX + "LINE_" + IntegerToString(row) + "_R", corner, rightX, y, shownRight, rightColor, rightSize, "Lucida Console");

   row++;
}

void DrawStatusPanel(SignalResult &signal)
{
   if(!ShowStatusPanel)
   {
      DeleteStatusPanelObjects();
      Comment("");
      return;
   }

   Comment("");

   BotStats stats = GetBotStats();
   ENUM_TIMEFRAMES entryTf = GetRequiredEntryTimeframe();
   string reasonLine1;
   string reasonLine2;

   string dailyGuardStatus = GetDailyGuardPanelStatus();
   string cooldownStatus = GetCooldownPanelStatus(stats);
   string spreadStatus = GetSpreadPanelStatus(signal.spreadPoints);
   string setupType = GetSetupTypeText(signal);
   string signalState = GetSignalStateText(signal);
   string profileLabel = InferProfileLabel();

   int panelCorner = StatusPanelCorner;
   int baseX = StatusPanelX;
   int baseY = StatusPanelY;

   // Stable fixed dashboard size
   int panelWidth = 390;
   int panelHeight = 770;
   int headerHeight = 34;
   int signalBarHeight = 28;

   int leftColX = 14;
   int rightColX = 275;

   color panelBg = C'14,16,22';
   color panelBorder = C'70,70,85';
   color headerBg = C'28,30,40';
   color headerBorder = C'90,90,110';
   color signalBarBg = C'22,24,32';
   color signalBarBorder = C'90,90,110';
   color labelColor = clrGainsboro;
   color sectionColor = clrDeepSkyBlue;
   color neutralColor = clrSilver;

   EnsureRectangleLabel(PANEL_PREFIX + "BG", panelCorner, baseX, baseY, panelWidth, panelHeight, panelBg, panelBorder);
   EnsureRectangleLabel(PANEL_PREFIX + "HEADER", panelCorner, baseX, baseY, panelWidth, headerHeight, headerBg, headerBorder);
   EnsureRectangleLabel(PANEL_PREFIX + "SIGNALBAR", panelCorner, baseX, baseY + headerHeight, panelWidth, signalBarHeight, signalBarBg, signalBarBorder);

   EnsureLabel(PANEL_PREFIX + "TITLE", panelCorner, baseX + 12, baseY + 7, "XAU PRO BOT", clrWhite, 12, "Arial Bold");
   EnsureLabel(PANEL_PREFIX + "SUBTITLE", panelCorner, baseX + 240, baseY + 8,
               GetStrategyModeName() + " | " + profileLabel,
               clrGold, 10, "Arial Bold");

   EnsureLabel(PANEL_PREFIX + "STATE", panelCorner, baseX + 12, baseY + headerHeight + 6,
               signalState, GetSignalStateColor(signal), 11, "Arial Bold");

   int row = 0;
   int linesBaseY = baseY + headerHeight + signalBarHeight + 12;

   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "MARKET", "----------------", sectionColor, sectionColor, true, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Chart TF", TimeframeToText((ENUM_TIMEFRAMES)Period()), labelColor, clrWhite, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Entry TF", TimeframeToText(entryTf), labelColor, clrWhite, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Session", GetSessionName(), labelColor, clrWhite, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Regime", RegimeToText(signal.regime), labelColor, neutralColor, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Trend", DirectionToPanelText(signal.direction), labelColor, GetDirectionColor(signal.direction), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Trend OK", BoolToText(signal.trendOk), labelColor, GetBoolColor(signal.trendOk), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Higher Bias", BoolToText(signal.higherBiasOk), labelColor, GetBoolColor(signal.higherBiasOk), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "ATR", DoubleToString(signal.atrValue, 2), labelColor, clrWhite, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Spread", IntegerToString(signal.spreadPoints) + " (" + spreadStatus + ")", labelColor, GetSpreadStatusColor(signal.spreadPoints), false, panelWidth);

   row++;
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "ENTRY LOGIC", "----------------", sectionColor, sectionColor, true, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Pullback", BoolToText(signal.pullbackOk), labelColor, GetBoolColor(signal.pullbackOk), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Rejection", BoolToText(signal.rejectionOk), labelColor, GetBoolColor(signal.rejectionOk), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Confirm", BoolToText(signal.confirmationOk), labelColor, GetBoolColor(signal.confirmationOk), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Extra Filter", BoolToText(signal.extraFilterOk), labelColor, GetBoolColor(signal.extraFilterOk), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Setup", setupType, labelColor,
                 signal.isBreakoutSignal ? clrGold : (signal.isPullbackSignal ? clrDeepSkyBlue : neutralColor),
                 false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Score", IntegerToString(signal.setupScore) + "/10", labelColor, GetScoreColor(signal.setupScore), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Strong", BoolToText(signal.isStrongSignal), labelColor, GetBoolColor(signal.isStrongSignal), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Entry", signal.isValid ? "READY" : "BLOCKED", labelColor, signal.isValid ? clrLimeGreen : clrTomato, false, panelWidth);

   row++;
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "TRADE PLAN", "----------------", sectionColor, sectionColor, true, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "SL", DoubleToString(signal.stopLossPrice, Digits), labelColor, clrWhite, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "TP", DoubleToString(signal.takeProfitPrice, Digits), labelColor, clrWhite, false, panelWidth);

   SplitReasonText(signal.reason, 20, reasonLine1, reasonLine2);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Reason", reasonLine1, labelColor, clrKhaki, false, panelWidth);
   if(StringLen(reasonLine2) > 0)
      DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "", reasonLine2, labelColor, clrKhaki, false, panelWidth);

   row++;
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "SESSION / RISK", "----------------", sectionColor, sectionColor, true, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Daily Guard", dailyGuardStatus, labelColor, GetGuardStatusColor(dailyGuardStatus), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Cooldown", cooldownStatus, labelColor, GetCooldownStatusColor(cooldownStatus), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Cooldown Bars", IntegerToString(stats.cooldownBarsRemaining), labelColor, clrWhite, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Open Positions", IntegerToString(stats.openPositions) + "/" + IntegerToString(MaxOpenPositions), labelColor, clrWhite, false, panelWidth);

   row++;
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "DAILY STATS", "----------------", sectionColor, sectionColor, true, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Trades Today", IntegerToString(stats.tradesToday), labelColor, clrWhite, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Wins Today", IntegerToString(stats.winsToday), labelColor, clrLimeGreen, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Losses Today", IntegerToString(stats.lossesToday), labelColor, clrTomato, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Consec Losses", IntegerToString(stats.consecutiveLosses), labelColor, stats.consecutiveLosses > 0 ? clrOrange : clrSilver, false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Daily PnL", DoubleToString(stats.dailyClosedPnL, 2) + " USD", labelColor, GetPnLColor(stats.dailyClosedPnL), false, panelWidth);
   DrawPanelLine(row, panelCorner, baseX, linesBaseY, leftColX, rightColX, "Daily Loss %", DoubleToString(GetCurrentDailyLossPercent(), 2) + "%", labelColor, GetCurrentDailyLossPercent() > 0 ? clrOrange : clrSilver, false, panelWidth);

   ChartRedraw();
}

#endif