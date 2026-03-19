#ifndef __XAU_TRADEMANAGER_MQH__
#define __XAU_TRADEMANAGER_MQH__

int g_lastHistoryTotal = 0;

double GetTrailATR()
{
   return iATR(Symbol(), GetManagementATRTimeframe(), ATRPeriod, 1);
}

double NormalizeLotForBroker(double lot)
{
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

   if(lotStep <= 0)
      lotStep = 0.01;

   lot = MathMax(minLot, MathMin(maxLot, lot));
   lot = MathFloor(lot / lotStep) * lotStep;

   if(lot < minLot)
      lot = minLot;

   return NormalizeDouble(lot, 2);
}

bool HasPartialCloseMarker(int ticket)
{
   string key = "XAU_PARTIAL_" + IntegerToString(ticket);
   return GlobalVariableCheck(key);
}

void MarkPartialCloseDone(int ticket)
{
   string key = "XAU_PARTIAL_" + IntegerToString(ticket);
   GlobalVariableSet(key, TimeCurrent());
}

bool IsBrokerStopDistanceValidForModify(int orderType, double referencePrice, double newSL, double tpPrice)
{
   int stopLevelPoints = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   double minStopDistance = stopLevelPoints * Point;

   if(minStopDistance <= 0)
      return true;

   if(orderType == OP_BUY)
   {
      if((referencePrice - newSL) < minStopDistance)
         return false;
      if(tpPrice > 0 && (tpPrice - referencePrice) < minStopDistance)
         return false;
   }
   else if(orderType == OP_SELL)
   {
      if((newSL - referencePrice) < minStopDistance)
         return false;
      if(tpPrice > 0 && (referencePrice - tpPrice) < minStopDistance)
         return false;
   }

   return true;
}

bool IsValidPartialCloseLots(double currentLots, double lotsToClose)
{
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);

   if(lotsToClose < minLot)
      return false;

   double remainingLots = NormalizeLotForBroker(currentLots - lotsToClose);

   if(remainingLots > 0 && remainingLots < minLot)
      return false;

   return true;
}

void InitializeTradeHistoryTracking()
{
   g_lastHistoryTotal = OrdersHistoryTotal();
   LogInfo("History tracking initialized at total: " + IntegerToString(g_lastHistoryTotal));
}

void TryPartialClose()
{
   if(!UsePartialClose)
      return;

   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      if(HasPartialCloseMarker(OrderTicket()))
         continue;

      double currentLots = OrderLots();
      double lotsToClose = NormalizeLotForBroker(currentLots * (PartialClosePercent / 100.0));

      if(!IsValidPartialCloseLots(currentLots, lotsToClose))
         continue;

      if(OrderType() == OP_BUY)
      {
         double profitPoints = (Bid - OrderOpenPrice()) / Point;

         if(profitPoints >= PartialCloseTriggerPoints)
         {
            RefreshRates();

            if(OrderClose(OrderTicket(), lotsToClose, Bid, Slippage, clrYellow))
            {
               MarkPartialCloseDone(OrderTicket());
               LogTrade("Partial close executed on BUY ticket: " + IntegerToString(OrderTicket()));
            }
            else
            {
               int err = GetLastError();
               LogError("Partial close failed on BUY | Code=" + IntegerToString(err));
               ResetLastError();
            }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double profitPoints = (OrderOpenPrice() - Ask) / Point;

         if(profitPoints >= PartialCloseTriggerPoints)
         {
            RefreshRates();

            if(OrderClose(OrderTicket(), lotsToClose, Ask, Slippage, clrYellow))
            {
               MarkPartialCloseDone(OrderTicket());
               LogTrade("Partial close executed on SELL ticket: " + IntegerToString(OrderTicket()));
            }
            else
            {
               int err = GetLastError();
               LogError("Partial close failed on SELL | Code=" + IntegerToString(err));
               ResetLastError();
            }
         }
      }
   }
}

void TryBreakEven()
{
   if(!UseBreakEven)
      return;

   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      if(OrderType() == OP_BUY)
      {
         double profitPoints = (Bid - OrderOpenPrice()) / Point;
         double targetSL = NormalizePrice(OrderOpenPrice() + BreakEvenLockPoints * Point);

         if(profitPoints >= BreakEvenTriggerPoints)
         {
            if((OrderStopLoss() == 0 || OrderStopLoss() < targetSL) &&
               targetSL < Bid &&
               IsBrokerStopDistanceValidForModify(OP_BUY, Bid, targetSL, OrderTakeProfit()))
            {
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrGreen))
               {
                  int err = GetLastError();
                  LogError("Failed moving BUY to breakeven | Code=" + IntegerToString(err));
                  ResetLastError();
               }
            }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double profitPoints = (OrderOpenPrice() - Ask) / Point;
         double targetSL = NormalizePrice(OrderOpenPrice() - BreakEvenLockPoints * Point);

         if(profitPoints >= BreakEvenTriggerPoints)
         {
            if((OrderStopLoss() == 0 || OrderStopLoss() > targetSL) &&
               targetSL > Ask &&
               IsBrokerStopDistanceValidForModify(OP_SELL, Ask, targetSL, OrderTakeProfit()))
            {
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrRed))
               {
                  int err = GetLastError();
                  LogError("Failed moving SELL to breakeven | Code=" + IntegerToString(err));
                  ResetLastError();
               }
            }
         }
      }
   }
}

void TryATRTrailing()
{
   if(!UseATRTrailing)
      return;

   double atr = GetTrailATR();
   if(atr <= 0)
      return;

   double trailDistance = atr * ATRTrailingMultiplier;

   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      if(OrderType() == OP_BUY)
      {
         double newSL = NormalizePrice(Bid - trailDistance);

         if(newSL > OrderStopLoss() &&
            newSL < Bid &&
            IsBrokerStopDistanceValidForModify(OP_BUY, Bid, newSL, OrderTakeProfit()))
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrAqua))
            {
               int err = GetLastError();
               LogError("ATR trailing failed on BUY | Code=" + IntegerToString(err));
               ResetLastError();
            }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double newSL = NormalizePrice(Ask + trailDistance);

         if((OrderStopLoss() == 0 || newSL < OrderStopLoss()) &&
            newSL > Ask &&
            IsBrokerStopDistanceValidForModify(OP_SELL, Ask, newSL, OrderTakeProfit()))
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrAqua))
            {
               int err = GetLastError();
               LogError("ATR trailing failed on SELL | Code=" + IntegerToString(err));
               ResetLastError();
            }
         }
      }
   }
}

void ManageOpenPositions()
{
   TryPartialClose();
   TryBreakEven();
   TryATRTrailing();
}

void UpdateClosedTradesStats()
{
   int historyTotal = OrdersHistoryTotal();

   if(historyTotal <= g_lastHistoryTotal)
      return;

   for(int i = g_lastHistoryTotal; i < historyTotal; i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      double profit = OrderProfit() + OrderSwap() + OrderCommission();

      RegisterTradeResult(profit);

      if(profit < 0)
         LogInfo("Trade closed LOSS | Profit=" + DoubleToString(profit, 2));
      else
         LogInfo("Trade closed WIN | Profit=" + DoubleToString(profit, 2));

      AppendClosedTradeToCSV();
   }

   g_lastHistoryTotal = historyTotal;
}

#endif