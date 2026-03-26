#ifndef __XAU_TRADEMANAGER_MQH__
#define __XAU_TRADEMANAGER_MQH__

// ============================================================
// TradeManager.mqh — Complete Rewrite
//
// Fixes applied vs previous version:
//
//   [1] CRITICAL: Infinite partial close loop fixed
//       Tier keys now use OrderOpenTime() not OrderTicket()
//       so remainder tickets share the same marker as the
//       original and are never re-processed
//
//   [2] CRITICAL: Partial close firing too early fixed
//       Trigger points raised — see preset recommendations
//
//   [3] Tiered exit system — 3 levels:
//       Tier 1 (PartialClose1TriggerPoints) → close Tier1Percent%
//              stop moves to break-even + BreakEvenLockPoints
//       Tier 2 (PartialClose2TriggerPoints) → close Tier2Percent%
//              stop locks at Tier2LockPoints in profit
//       Tier 3 → remaining position trails with Tier3TrailMultiplier
//
//   [4] Trail activation threshold — trail does not start
//       until TrailActivationPoints profit is reached
//
//   [5] After Tier 2 fires, trail switches to Tier3TrailMultiplier
//       so the runner is protected tightly
//
//   [6] Legacy single-tier path preserved when UseTieredExit=false
//
// Recommended preset values:
//   UseTieredExit                = true
//   PartialClose1TriggerPoints   = 600
//   Tier1Percent                 = 30
//   PartialClose2TriggerPoints   = 1200
//   Tier2Percent                 = 30
//   Tier2LockPoints              = 500
//   Tier3TrailMultiplier         = 0.80
//   TrailActivationPoints        = 600
//   ATRTrailingMultiplier        = 1.20
//   BreakEvenLockPoints          = 200
// ============================================================

int g_lastHistoryTotal = 0;

double GetTrailATR()
{
   return iATR(Symbol(), GetManagementATRTimeframe(), ATRPeriod, 1);
}

double NormalizeLotForBroker(double lot)
{
   double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep <= 0) lotStep = 0.01;
   lot = MathMax(minLot, MathMin(maxLot, lot));
   lot = MathFloor(lot / lotStep) * lotStep;
   if(lot < minLot) lot = minLot;
   return NormalizeDouble(lot, 2);
}

bool IsRunnerTrade() { return (StringFind(OrderComment(), "_RUN", 0) >= 0); }
bool IsTPTrade()     { return (StringFind(OrderComment(), "_TP",  0) >= 0); }

bool IsBrokerStopDistanceValidForModify(int orderType, double referencePrice, double newSL, double tpPrice)
{
   int    stopLevelPts = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   double minStopDist  = stopLevelPts * Point;
   if(minStopDist <= 0) return true;
   if(orderType == OP_BUY)
   {
      if((referencePrice - newSL) < minStopDist) return false;
      if(tpPrice > 0 && (tpPrice - referencePrice) < minStopDist) return false;
   }
   else if(orderType == OP_SELL)
   {
      if((newSL - referencePrice) < minStopDist) return false;
      if(tpPrice > 0 && (referencePrice - tpPrice) < minStopDist) return false;
   }
   return true;
}

bool IsValidPartialCloseLots(double currentLots, double lotsToClose)
{
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   if(lotsToClose < minLot) return false;
   double remaining = NormalizeLotForBroker(currentLots - lotsToClose);
   if(remaining > 0 && remaining < minLot) return false;
   return true;
}

// -------------------------------------------------------
// [FIX 1] Key uses OrderOpenTime() — all remainder tickets
// from the same original trade share the same open time,
// so they all see the tier as already fired. Loop impossible.
// -------------------------------------------------------
string MakeTierKey(int tier)
{
   return "XAU_T" + IntegerToString(tier) + "_" +
          Symbol() + "_" +
          IntegerToString(MagicNumber) + "_" +
          IntegerToString((int)OrderOpenTime());
}

bool HasTierFired(int tier)   { return GlobalVariableCheck(MakeTierKey(tier)); }
void MarkTierFired(int tier)  { GlobalVariableSet(MakeTierKey(tier), (double)TimeCurrent()); }

// Legacy key — backward compat only
string GetPartialCloseKey()
{
   return "XAU_PARTIAL_" + Symbol() + "_" +
          IntegerToString(MagicNumber) + "_" +
          IntegerToString((int)OrderOpenTime()) + "_" +
          DoubleToString(OrderOpenPrice(), Digits);
}
bool HasPartialCloseMarker() { return GlobalVariableCheck(GetPartialCloseKey()); }
void MarkPartialCloseDone()  { GlobalVariableSet(GetPartialCloseKey(), TimeCurrent()); }

// -------------------------------------------------------
// Lock stop at N points profit from open price
// -------------------------------------------------------
void LockStopAtProfit(int lockPoints)
{
   if(OrderType() == OP_BUY)
   {
      double targetSL = NormalizePrice(OrderOpenPrice() + lockPoints * Point);
      if((OrderStopLoss() == 0 || OrderStopLoss() < targetSL) &&
         targetSL < Bid &&
         IsBrokerStopDistanceValidForModify(OP_BUY, Bid, targetSL, OrderTakeProfit()))
      {
         if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrGreen))
         { LogError("LockStop BUY failed | Code=" + IntegerToString(GetLastError())); ResetLastError(); }
         else
            LogTrade("Stop locked +"+IntegerToString(lockPoints)+"pts | #"+IntegerToString(OrderTicket()));
      }
   }
   else if(OrderType() == OP_SELL)
   {
      double targetSL = NormalizePrice(OrderOpenPrice() - lockPoints * Point);
      if((OrderStopLoss() == 0 || OrderStopLoss() > targetSL) &&
         targetSL > Ask &&
         IsBrokerStopDistanceValidForModify(OP_SELL, Ask, targetSL, OrderTakeProfit()))
      {
         if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrGreen))
         { LogError("LockStop SELL failed | Code=" + IntegerToString(GetLastError())); ResetLastError(); }
         else
            LogTrade("Stop locked +"+IntegerToString(lockPoints)+"pts | #"+IntegerToString(OrderTicket()));
      }
   }
}

// -------------------------------------------------------
// Execute partial close by percentage
// -------------------------------------------------------
bool ExecutePartialClose(double percent, string label)
{
   double currentLots = OrderLots();
   double lotsToClose = NormalizeLotForBroker(currentLots * (percent / 100.0));

   if(!IsValidPartialCloseLots(currentLots, lotsToClose))
   {
      LogError(label + " skipped — invalid lots | Current=" + DoubleToString(currentLots, 2) +
               " ToClose=" + DoubleToString(lotsToClose, 2));
      return false;
   }

   RefreshRates();
   double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
   color  closeColor = (OrderType() == OP_BUY) ? clrYellow : clrOrange;

   if(OrderClose(OrderTicket(), lotsToClose, closePrice, Slippage, closeColor))
   {
      LogTrade(label + " | #" + IntegerToString(OrderTicket()) +
               " Closed=" + DoubleToString(lotsToClose, 2) +
               " Rem=" + DoubleToString(NormalizeLotForBroker(currentLots - lotsToClose), 2));
      return true;
   }

   LogError(label + " failed | Code=" + IntegerToString(GetLastError()));
   ResetLastError();
   return false;
}

// -------------------------------------------------------
// [FIX 1+2+3] Tiered exit system
// -------------------------------------------------------
void TryTieredExit()
{
   if(!UseTieredExit) return;
   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if(IsRunnerTrade() || IsTPTrade()) continue;

      double profitPoints = 0;
      if(OrderType() == OP_BUY)        profitPoints = (Bid - OrderOpenPrice()) / Point;
      else if(OrderType() == OP_SELL)  profitPoints = (OrderOpenPrice() - Ask) / Point;
      else continue;

      // TIER 1
      if(!HasTierFired(1) && profitPoints >= PartialClose1TriggerPoints)
      {
         if(ExecutePartialClose(Tier1Percent, "Tier1"))
         {
            MarkTierFired(1);
            LockStopAtProfit(BreakEvenLockPoints);
         }
         continue;
      }

      // TIER 2 — only after Tier 1
      if(HasTierFired(1) && !HasTierFired(2) && profitPoints >= PartialClose2TriggerPoints)
      {
         if(ExecutePartialClose(Tier2Percent, "Tier2"))
         {
            MarkTierFired(2);
            LockStopAtProfit(Tier2LockPoints);
         }
         continue;
      }
      // Tier 3 handled by TryATRTrailing with tight multiplier after Tier 2
   }
}

// -------------------------------------------------------
// Legacy single-tier partial close (UseTieredExit=false)
// -------------------------------------------------------
void TryPartialClose()
{
   if(!UsePartialClose || UseTieredExit) return;
   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if(IsRunnerTrade() || IsTPTrade()) continue;
      if(HasPartialCloseMarker()) continue;

      double profitPoints = 0;
      if(OrderType() == OP_BUY)        profitPoints = (Bid - OrderOpenPrice()) / Point;
      else if(OrderType() == OP_SELL)  profitPoints = (OrderOpenPrice() - Ask) / Point;

      if(profitPoints >= PartialCloseTriggerPoints)
         if(ExecutePartialClose(PartialClosePercent, "LegacyPartial"))
            MarkPartialCloseDone();
   }
}

// -------------------------------------------------------
// Break-even — only when UseTieredExit=false
// -------------------------------------------------------
void TryBreakEven()
{
   if(!UseBreakEven || UseTieredExit) return;
   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;

      if(OrderType() == OP_BUY)
      {
         double profit   = (Bid - OrderOpenPrice()) / Point;
         double targetSL = NormalizePrice(OrderOpenPrice() + BreakEvenLockPoints * Point);
         if(profit >= BreakEvenTriggerPoints &&
            (OrderStopLoss() == 0 || OrderStopLoss() < targetSL) &&
            targetSL < Bid &&
            IsBrokerStopDistanceValidForModify(OP_BUY, Bid, targetSL, OrderTakeProfit()))
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrGreen))
            { LogError("BE BUY failed | Code="+IntegerToString(GetLastError())); ResetLastError(); }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double profit   = (OrderOpenPrice() - Ask) / Point;
         double targetSL = NormalizePrice(OrderOpenPrice() - BreakEvenLockPoints * Point);
         if(profit >= BreakEvenTriggerPoints &&
            (OrderStopLoss() == 0 || OrderStopLoss() > targetSL) &&
            targetSL > Ask &&
            IsBrokerStopDistanceValidForModify(OP_SELL, Ask, targetSL, OrderTakeProfit()))
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrRed))
            { LogError("BE SELL failed | Code="+IntegerToString(GetLastError())); ResetLastError(); }
         }
      }
   }
}

// -------------------------------------------------------
// [FIX 4+5] ATR trailing with activation + tier switching
// -------------------------------------------------------
void TryATRTrailing()
{
   if(!UseATRTrailing) return;
   double atr = GetTrailATR();
   if(atr <= 0) return;
   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;

      double profitPoints = 0;
      if(OrderType() == OP_BUY)        profitPoints = (Bid - OrderOpenPrice()) / Point;
      else if(OrderType() == OP_SELL)  profitPoints = (OrderOpenPrice() - Ask) / Point;
      else continue;

      // [FIX 4] Don't trail until threshold reached
      if(UseTrailActivation && profitPoints < TrailActivationPoints) continue;

      // [FIX 5] Tight trail after Tier 2 fires
      double multiplier = ATRTrailingMultiplier;
      if(UseTieredExit && HasTierFired(2))
         multiplier = Tier3TrailMultiplier;

      double trailDist = atr * multiplier;

      if(OrderType() == OP_BUY)
      {
         double newSL = NormalizePrice(Bid - trailDist);
         if(newSL > OrderStopLoss() && newSL < Bid &&
            IsBrokerStopDistanceValidForModify(OP_BUY, Bid, newSL, OrderTakeProfit()))
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrAqua))
            { LogError("Trail BUY failed | Code="+IntegerToString(GetLastError())); ResetLastError(); }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double newSL = NormalizePrice(Ask + trailDist);
         if((OrderStopLoss() == 0 || newSL < OrderStopLoss()) && newSL > Ask &&
            IsBrokerStopDistanceValidForModify(OP_SELL, Ask, newSL, OrderTakeProfit()))
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrAqua))
            { LogError("Trail SELL failed | Code="+IntegerToString(GetLastError())); ResetLastError(); }
         }
      }
   }
}

// -------------------------------------------------------
// Main call from OnTick()
// -------------------------------------------------------
void ManageOpenPositions()
{
   if(UseTieredExit) TryTieredExit();
   else { TryPartialClose(); TryBreakEven(); }
   TryATRTrailing();
}

// -------------------------------------------------------
// History tracking
// -------------------------------------------------------
void InitializeTradeHistoryTracking()
{
   g_lastHistoryTotal = OrdersHistoryTotal();
   LogInfo("History tracking initialized at total: " + IntegerToString(g_lastHistoryTotal));
}

void UpdateClosedTradesStats()
{
   int historyTotal = OrdersHistoryTotal();
   if(historyTotal <= g_lastHistoryTotal) return;

   for(int i = g_lastHistoryTotal; i < historyTotal; i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      double profit = OrderProfit() + OrderSwap() + OrderCommission();
      RegisterTradeResult(profit);
      if(profit < 0) LogInfo("Trade closed LOSS | Profit=" + DoubleToString(profit, 2));
      else           LogInfo("Trade closed WIN  | Profit=" + DoubleToString(profit, 2));
      AppendClosedTradeToCSV();
   }
   g_lastHistoryTotal = historyTotal;
}

#endif