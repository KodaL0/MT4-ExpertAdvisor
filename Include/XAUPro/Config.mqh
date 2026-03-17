#ifndef __XAU_CONFIG_MQH__
#define __XAU_CONFIG_MQH__

input int MagicNumber = 20260316;
input int Slippage = 10;
input int MaxSpreadPoints = 80;

input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;
input int FastEMA = 50;
input int SlowEMA = 200;
input int PullbackEMA1 = 20;
input int PullbackEMA2 = 50;

input int ATRPeriod = 14;
input double MinATR = 2.0;
input double MaxATR = 1000.0;

input bool UseATRStops = true;
input double ATRStopMultiplier = 0.5;
input double ATRTakeProfitMultiplier = 1.0;

input bool UseRegimeFilter = true;
input double RegimeMinATR = 3.0;
input double RegimeMaxATR = 25.0;
input double RegimeMinEMASeparationPoints = 120.0;
input double RegimeChaoticCandleATRRatio = 2.5;

input bool UseSessionPreset = true;
input int SessionPreset = 3; // 1=London, 2=NewYork, 3=London+NY, 4=Custom
input int StartHour = 0;
input int EndHour = 24;

input bool UseRiskPercent = true;
input double RiskPercent = 1.0;
input double FixedLotSize = 0.01;

input int StopLossPoints = 300;
input int TakeProfitPoints = 600;

input bool UseBreakEven = true;
input int BreakEvenTriggerPoints = 300;
input int BreakEvenLockPoints = 50;

input bool UsePartialClose = true;
input double PartialClosePercent = 50.0;
input int PartialCloseTriggerPoints = 300;

input bool UseATRTrailing = true;
input double ATRTrailingMultiplier = 1.5;

input bool UseDailyGuard = true;
input int MaxTradesPerDay = 5;
input int MaxConsecutiveLosses = 3;
input bool UseMaxDailyLossPercent = true;
input double MaxDailyLossPercent = 2.0;

input int MaxOpenPositions = 1;

input bool UseAbnormalCandleFilter = true;
input double MaxCandleToATRRatio = 2.0;

input bool UseEMASeparationFilter = true;
input double MinEMASeparationPoints = 150;

input bool EnableDebugLogs = true;
input bool EnableVerboseSignalLogs = true;

input bool DeveloperTestMode = false;
input bool DeveloperIgnoreConfirmation = false;
input bool DeveloperIgnoreExtraFilter = false;
input bool DeveloperIgnoreAbnormalCandle = false;
input bool DeveloperIgnoreTrendStrength = false;
input bool DeveloperIgnoreRejection = false;
input bool DeveloperIgnoreRegimeFilter = false;

input bool ShowStatusPanel = true;
input int StatusPanelCorner = 0;
input int StatusPanelX = 10;
input int StatusPanelY = 20;

input bool EnableCSVLogging = true;
input string CSVFileName = "XAU_Pro_TradeLog.csv";

#endif