#ifndef __XAU_TYPES_MQH__
#define __XAU_TYPES_MQH__

enum TradeDirection
{
   DIR_NONE = 0,
   DIR_BUY  = 1,
   DIR_SELL = -1
};

struct SignalResult
{
   bool isValid;
   int direction;
   string reason;
   string label;
   double entryPrice;
   double stopLossPrice;
   double takeProfitPrice;

   bool trendOk;
   bool pullbackOk;
   bool rejectionOk;
   bool confirmationOk;
   bool extraFilterOk;

   double atrValue;
   int spreadPoints;
   double emaFast;
   double emaSlow;
};

struct BotStats
{
   int tradesToday;
   int winsToday;
   int lossesToday;
   int consecutiveLosses;
   int openPositions;
   double dailyClosedPnL;
};

#endif