#property strict

input double LotSize = 0.01;
input int StopLossPoints = 300;
input int TakeProfitPoints = 600;
input int MaxSpreadPoints = 80;
input int Slippage = 10;
input int MagicNumber = 20260316;

input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;
input int FastEMA = 50;
input int SlowEMA = 200;
input int PullbackEMA1 = 20;
input int PullbackEMA2 = 50;
input int ATRPeriod = 14;
input double MinATR = 2.0;

input int StartHour = 0;
input int EndHour = 24;

input bool UseBreakEven = true;
input int BreakEvenTriggerPoints = 300;
input int BreakEvenLockPoints = 50;

datetime lastBarTime = 0;

//==================================================
// Helpers
//==================================================
bool IsNewBar()
{
   datetime currentBarTime = Time[0];
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

bool IsCorrectSymbol()
{
   if(Symbol() == "XAUUSD" || Symbol() == "GOLD")
      return true;

   if(StringFind(Symbol(), "XAUUSD", 0) == 0)
      return true;

   return false;
}

bool IsCorrectTimeframe()
{
   return Period() == PERIOD_M15;
}

bool IsSpreadOk()
{
   int spread = (int)((Ask - Bid) / Point);
   return (spread <= MaxSpreadPoints);
}

bool IsTradingHour()
{
   int hour = TimeHour(TimeCurrent());

   if(StartHour < EndHour)
      return (hour >= StartHour && hour < EndHour);

   return (hour >= StartHour || hour < EndHour);
}

bool IsVolatilityOk()
{
   double atr = iATR(Symbol(), PERIOD_M15, ATRPeriod, 1);
   return atr >= MinATR;
}

bool HasOpenPosition()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            return true;
      }
   }
   return false;
}

int GetTrendDirection()
{
   double fast = iMA(Symbol(), TrendTimeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slow = iMA(Symbol(), TrendTimeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);

   if(fast > slow) return 1;
   if(fast < slow) return -1;
   return 0;
}

double NormalizePrice(double price)
{
   return NormalizeDouble(price, Digits);
}

//==================================================
// Signal Logic
//==================================================
bool BuySignal()
{
   if(GetTrendDirection() != 1)
      return false;

   double ema20 = iMA(Symbol(), PERIOD_M15, PullbackEMA1, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ema50 = iMA(Symbol(), PERIOD_M15, PullbackEMA2, 0, MODE_EMA, PRICE_CLOSE, 1);

   double prevLow = Low[1];
   double prevOpen = Open[1];
   double prevClose = Close[1];
   double currOpen = Open[0];
   double currClose = Close[0];

   bool pulledBack = (prevLow <= ema20 || prevLow <= ema50);
   bool prevRejectedLower = (prevClose > prevOpen);
   bool bullishMomentum = (currClose > currOpen);

   return pulledBack && prevRejectedLower && bullishMomentum;
}

bool SellSignal()
{
   if(GetTrendDirection() != -1)
      return false;

   double ema20 = iMA(Symbol(), PERIOD_M15, PullbackEMA1, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ema50 = iMA(Symbol(), PERIOD_M15, PullbackEMA2, 0, MODE_EMA, PRICE_CLOSE, 1);

   double prevHigh = High[1];
   double prevOpen = Open[1];
   double prevClose = Close[1];
   double currOpen = Open[0];
   double currClose = Close[0];

   bool pulledBack = (prevHigh >= ema20 || prevHigh >= ema50);
   bool prevRejectedHigher = (prevClose < prevOpen);
   bool bearishMomentum = (currClose < currOpen);

   return pulledBack && prevRejectedHigher && bearishMomentum;
}

//==================================================
// Trade Management
//==================================================
void ManageOpenPosition()
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
               bool modified = OrderModify(
                  OrderTicket(),
                  OrderOpenPrice(),
                  targetSL,
                  OrderTakeProfit(),
                  0,
                  clrGreen
               );

               if(!modified)
                  Print("Failed to move BUY to breakeven. Error: ", GetLastError());
            }
         }
      }

      if(OrderType() == OP_SELL)
      {
         double profitPoints = (OrderOpenPrice() - Ask) / Point;
         double targetSL = NormalizePrice(OrderOpenPrice() - BreakEvenLockPoints * Point);

         if(profitPoints >= BreakEvenTriggerPoints)
         {
            if(OrderStopLoss() == 0 || OrderStopLoss() > targetSL)
            {
               bool modified = OrderModify(
                  OrderTicket(),
                  OrderOpenPrice(),
                  targetSL,
                  OrderTakeProfit(),
                  0,
                  clrRed
               );

               if(!modified)
                  Print("Failed to move SELL to breakeven. Error: ", GetLastError());
            }
         }
      }
   }
}

//==================================================
// Execution
//==================================================
void OpenBuy()
{
   double sl = NormalizePrice(Ask - StopLossPoints * Point);
   double tp = NormalizePrice(Ask + TakeProfitPoints * Point);

   int ticket = OrderSend(
      Symbol(),
      OP_BUY,
      LotSize,
      Ask,
      Slippage,
      sl,
      tp,
      "XAU Pro Buy",
      MagicNumber,
      0,
      clrGreen
   );

   if(ticket < 0)
      Print("Buy order failed. Error: ", GetLastError());
   else
      Print("Buy order opened. Ticket: ", ticket);
}

void OpenSell()
{
   double sl = NormalizePrice(Bid + StopLossPoints * Point);
   double tp = NormalizePrice(Bid - TakeProfitPoints * Point);

   int ticket = OrderSend(
      Symbol(),
      OP_SELL,
      LotSize,
      Bid,
      Slippage,
      sl,
      tp,
      "XAU Pro Sell",
      MagicNumber,
      0,
      clrRed
   );

   if(ticket < 0)
      Print("Sell order failed. Error: ", GetLastError());
   else
      Print("Sell order opened. Ticket: ", ticket);
}

//==================================================
// Lifecycle
//==================================================
int OnInit()
{
   Print("XAUUSD Pro Bot initialized");
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   if(!IsCorrectSymbol())
      return;

   if(!IsCorrectTimeframe())
      return;

   ManageOpenPosition();

   if(!IsNewBar())
      return;

   if(!IsTradingHour())
   {
      Print("Outside trading hours.");
      return;
   }

   if(!IsSpreadOk())
   {
      Print("Spread too high, skipping trade.");
      return;
   }

   if(!IsVolatilityOk())
   {
      Print("ATR too low, skipping trade.");
      return;
   }

   if(HasOpenPosition())
      return;

   if(BuySignal())
   {
      OpenBuy();
      return;
   }

   if(SellSignal())
   {
      OpenSell();
      return;
   }
}