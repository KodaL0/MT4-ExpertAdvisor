#ifndef __XAU_TRADEMANAGER_MQH__
#define __XAU_TRADEMANAGER_MQH__

int g_lastHistoryTotal = 0;

double GetTrailATR()
{
   return iATR(Symbol(), PERIOD_M15, ATRPeriod, 1);
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

void InitializeTradeHistoryTracking()
{
   g_lastHistoryTotal = OrdersHistoryTotal();
   LogInfo("History tracking initialized at total: " + IntegerToString(g_lastHistoryTotal));
}

void TryPartialClose()
{
   if(!UsePartialClose)
      return;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      if(HasPartialCloseMarker(OrderTicket()))
         continue;

      double lotsToClose = NormalizeLotForBroker(OrderLots() * (PartialClosePercent / 100.0));
      double minLot = MarketInfo(Symbol(), MODE_MINLOT);

      if(lotsToClose < minLot)
         continue;

      if(OrderType() == OP_BUY)
      {
         double profitPoints = (Bid - OrderOpenPrice()) / Point;

         if(profitPoints >= PartialCloseTriggerPoints)
         {
            if(OrderClose(OrderTicket(), lotsToClose, Bid, Slippage, clrYellow))
            {
               MarkPartialCloseDone(OrderTicket());
               LogTrade("Partial close executed on BUY ticket: " + IntegerToString(OrderTicket()));
            }
            else
            {
               LogError("Partial close failed on BUY");
            }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double profitPoints = (OrderOpenPrice() - Ask) / Point;

         if(profitPoints >= PartialCloseTriggerPoints)
         {
            if(OrderClose(OrderTicket(), lotsToClose, Ask, Slippage, clrYellow))
            {
               MarkPartialCloseDone(OrderTicket());
               LogTrade("Partial close executed on SELL ticket: " + IntegerToString(OrderTicket()));
            }
            else
            {
               LogError("Partial close failed on SELL");
            }
         }
      }
   }
}

void TryBreakEven()
{
   if(!UseBreakEven)
      return;

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
            if(OrderStopLoss() < targetSL)
            {
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrGreen))
                  LogError("Failed moving BUY to breakeven");
            }
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double profitPoints = (OrderOpenPrice() - Ask) / Point;
         double targetSL = NormalizePrice(OrderOpenPrice() - BreakEvenLockPoints * Point);

         if(profitPoints >= BreakEvenTriggerPoints)
         {
            if(OrderStopLoss() == 0 || OrderStopLoss() > targetSL)
            {
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrRed))
                  LogError("Failed moving SELL to breakeven");
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

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      if(OrderType() == OP_BUY)
      {
         double newSL = NormalizePrice(Bid - trailDistance);

         if(newSL > OrderStopLoss() && newSL < Bid)
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrAqua))
               LogError("ATR trailing failed on BUY");
         }
      }
      else if(OrderType() == OP_SELL)
      {
         double newSL = NormalizePrice(Ask + trailDistance);

         if((OrderStopLoss() == 0 || newSL < OrderStopLoss()) && newSL > Ask)
         {
            if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrAqua))
               LogError("ATR trailing failed on SELL");
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