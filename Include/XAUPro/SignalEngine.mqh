#ifndef __XAU_SIGNALENGINE_MQH__
#define __XAU_SIGNALENGINE_MQH__

string DirectionToText(int dir)
{
   if(dir == DIR_BUY) return "BUY";
   if(dir == DIR_SELL) return "SELL";
   return "NONE";
}

string BoolText(bool value)
{
   return value ? "YES" : "NO";
}

double GetDynamicStopDistancePrice(double atrValue)
{
   if(UseATRStops)
      return atrValue * ATRStopMultiplier;

   return StopLossPoints * Point;
}

double GetDynamicTakeProfitDistancePrice(double atrValue)
{
   if(UseATRStops)
      return atrValue * ATRTakeProfitMultiplier;

   return TakeProfitPoints * Point;
}

void LogSignalDiagnostics(SignalResult &r)
{
   if(!EnableVerboseSignalLogs)
      return;

   Print("===== SIGNAL CHECK =====");
   Print("Strategy       : ", GetStrategyModeName());
   Print("Direction      : ", DirectionToText(r.direction));
   Print("Regime         : ", RegimeToText(r.regime));
   Print("Trend OK       : ", BoolText(r.trendOk));
   Print("Higher Bias OK : ", BoolText(r.higherBiasOk));
   Print("Pullback OK    : ", BoolText(r.pullbackOk));
   Print("Rejection OK   : ", BoolText(r.rejectionOk));
   Print("Confirmation OK: ", BoolText(r.confirmationOk));
   Print("Extra Filter OK: ", BoolText(r.extraFilterOk));
   Print("ATR            : ", DoubleToString(r.atrValue, 2));
   Print("Spread         : ", IntegerToString(r.spreadPoints));
   Print("EMA Fast       : ", DoubleToString(r.emaFast, 2));
   Print("EMA Slow       : ", DoubleToString(r.emaSlow, 2));
   Print("H4 EMA Fast    : ", DoubleToString(r.h4Fast, 2));
   Print("H4 EMA Slow    : ", DoubleToString(r.h4Slow, 2));
   Print("SL Price       : ", DoubleToString(r.stopLossPrice, Digits));
   Print("TP Price       : ", DoubleToString(r.takeProfitPrice, Digits));
   Print("Result         : ", r.reason);
   Print("========================");
}

#include <XAUPro/SignalEngineTrend.mqh>
#include <XAUPro/SignalEngineSniper.mqh>

SignalResult BuildSignal(bool doLog = true)
{
   if(StrategyMode == 2)
      return BuildSniperSignal(doLog);

   return BuildTrendSignal(doLog);
}

#endif