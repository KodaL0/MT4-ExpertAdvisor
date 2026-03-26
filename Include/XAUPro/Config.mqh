#ifndef __XAU_CONFIG_MQH__
#define __XAU_CONFIG_MQH__

input int MagicNumber = 20260316;
input int Slippage = 10;
input int MaxSpreadPoints = 150;

// ===============================
// Strategy Selection
// ===============================
input int StrategyMode = 1; // 1=Trend Pro, 2=Sniper M5

// ===============================
// Trend Pro Settings
// ===============================
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;
input ENUM_TIMEFRAMES HigherBiasTimeframe = PERIOD_H4;
input int FastEMA = 50;
input int SlowEMA = 200;
input int PullbackEMA1 = 20;
input int PullbackEMA2 = 50;

// ===============================
// Sniper Settings
// ===============================
input ENUM_TIMEFRAMES SniperBiasTimeframe = PERIOD_M15;
input int SniperFastEMA = 50;
input int SniperSlowEMA = 200;
input int SniperPullbackEMA = 20;
input bool SniperUseSecondEMA = true;
input int SniperPullbackEMA2 = 50;
input bool UseSniperATRProfile = true;
input double SniperATRStopMultiplier = 0.60;
input double SniperATRTakeProfitMultiplier = 1.20;

// ===============================
// Sniper Score Thresholds
// ===============================
input int SniperPullbackScoreMin = 4;
input int SniperBreakoutScoreMin = 5;

// ===============================
// Volatility / ATR
// ===============================
input int ATRPeriod = 14;
input double MinATR = 2.0;
input double MaxATR = 1000.0;

input bool UseATRStops = true;
input double ATRStopMultiplier = 0.75;
input double ATRTakeProfitMultiplier = 1.50;

// ===============================
// Regime Filter
// ===============================
input bool UseRegimeFilter = true;
input double RegimeMinATR = 3.0;
input double RegimeMaxATR = 25.0;
input double RegimeMinEMASeparationPoints = 80.0;
input double RegimeChaoticCandleATRRatio = 2.5;

// ===============================
// Trend Pro Higher-Timeframe Bias
// ===============================
input bool UseMultiTimeframeBias = true;

// ===============================
// Sessions
// ===============================
input bool UseSessionPreset = true;
input int SessionPreset = 3;
input int StartHour = 0;
input int EndHour = 24;
input int ActiveSessionStartHour = 7;  // overridden by preset
input int ActiveSessionEndHour   = 20; // overridden by preset

// ===============================
// Risk
// ===============================
input bool UseRiskPercent = true;
input double RiskPercent = 0.10;
input double FixedLotSize = 0.01;

// ===== NEW RISK SAFETY SETTINGS =====
input bool RiskUseEquity = true;
input double MaxCalculatedLot = 1.00;
input int MinStopDistancePoints = 800;

// ===============================
// Fixed SL/TP fallback
// ===============================
input int StopLossPoints = 300;
input int TakeProfitPoints = 600;

// ===============================
// Trade Management
// ===============================
input bool UseTieredExit = true;

input bool UseBreakEven = true;
input int BreakEvenTriggerPoints = 300;
input int BreakEvenLockPoints = 200;

input bool UsePartialClose = true;
input double PartialClosePercent = 50.0;
input int PartialCloseTriggerPoints = 300;

input int PartialClose1TriggerPoints = 600;
input double Tier1Percent = 30.0;

input int PartialClose2TriggerPoints = 1200;
input double Tier2Percent = 30.0;
input int Tier2LockPoints = 500;

input bool UseATRTrailing = true;
input double ATRTrailingMultiplier = 1.20;

input bool UseTrailActivation = true;
input int TrailActivationPoints = 600;

input double Tier3TrailMultiplier = 0.80;

// ===============================
// Daily Guard
// ===============================
input bool UseDailyGuard = true;
input int MaxTradesPerDay = 10;
input int MaxConsecutiveLosses = 3;
input bool UseMaxDailyLossPercent = true;
input double MaxDailyLossPercent = 2.0;

input int MaxOpenPositions = 1;

// ===============================
// Filters
// ===============================
input bool UseAbnormalCandleFilter = true;
input double MaxCandleToATRRatio = 2.0;

input bool UseEMASeparationFilter = true;
input double MinEMASeparationPoints = 120.0;

// ===============================
// Logging
// ===============================
input bool EnableDebugLogs = true;
input bool EnableVerboseSignalLogs = true;

// ===============================
// HTF Structure Filter
// ===============================
input bool   UseHTFStructureFilter = true;
input int    HTFStructureTimeframe  = 60;   // 60=H1, 240=H4
input int    HTFSwingLookback       = 40;
input double HTFStructureBufferATR  = 0.30;

// ===============================
// Developer Mode
// ===============================
input bool DeveloperTestMode = false;
input bool DeveloperIgnoreConfirmation = false;
input bool DeveloperIgnoreExtraFilter = false;
input bool DeveloperIgnoreAbnormalCandle = false;
input bool DeveloperIgnoreTrendStrength = false;
input bool DeveloperIgnoreRejection = false;
input bool DeveloperIgnoreRegimeFilter = false;
input bool DeveloperIgnoreMultiTimeframeBias = false;

// ===============================
// Spread Spike Protection
// ===============================
input bool UseSpreadSpikeProtection = true;
input int SpreadAveragePeriod = 30;
input double SpreadSpikeMultiplier = 2.5;

// ===============================
// Trade Cooldown Protection
// ===============================
input bool UseTradeCooldown = true;
input int CooldownBarsAfterTrade = 2;
input int CooldownBarsAfterLoss = 5;

// ===============================
// UI
// ===============================
input bool ShowStatusPanel = true;
input int StatusPanelCorner = 0;
input int StatusPanelX = 10;
input int StatusPanelY = 20;

// ===============================
// CSV Journal
// ===============================
input bool EnableCSVLogging = true;
input string CSVFileName = "XAU_Pro_TradeLog.csv";

#endif