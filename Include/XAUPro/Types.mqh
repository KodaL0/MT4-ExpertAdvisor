#ifndef __XAU_TYPES_MQH__
#define __XAU_TYPES_MQH__

enum TradeDirection
{
   DIR_NONE = 0,
   DIR_BUY  = 1,
   DIR_SELL = -1
};

enum MarketRegime
{
   REGIME_UNKNOWN = 0,
   REGIME_TRENDING = 1,
   REGIME_RANGING = 2,
   REGIME_CHAOTIC = 3,
   REGIME_DEAD = 4
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
   bool higherBiasOk;

   double atrValue;
   int spreadPoints;
   double emaFast;
   double emaSlow;
   double h4Fast;
   double h4Slow;
   int regime;

   // 🔥 NEW FIELDS
   int setupScore;
   bool isStrongSignal;
   bool isBreakoutSignal;
   bool isPullbackSignal;
};

struct BotStats
{
   int tradesToday;
   int winsToday;
   int lossesToday;
   int consecutiveLosses;
   int openPositions;
   double dailyClosedPnL;
   int cooldownBarsRemaining;
};

#endif