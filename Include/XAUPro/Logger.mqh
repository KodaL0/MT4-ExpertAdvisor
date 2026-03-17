#ifndef __XAU_LOGGER_MQH__
#define __XAU_LOGGER_MQH__

void LogInfo(string msg)
{
   Print("[INFO] ", msg);
}

void LogSkip(string msg)
{
   Print("[SKIP] ", msg);
}

void LogTrade(string msg)
{
   Print("[TRADE] ", msg);
}

void LogError(string msg)
{
   int err = GetLastError();
   Print("[ERROR] ", msg, " | Code=", err);
   ResetLastError();
}

void LogDebug(string msg)
{
   if(!EnableDebugLogs)
      return;

   Print("[DEBUG] ", msg);
}

#endif