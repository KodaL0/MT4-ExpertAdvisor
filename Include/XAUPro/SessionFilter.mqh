#ifndef __XAU_SESSIONFILTER_MQH__
#define __XAU_SESSIONFILTER_MQH__

bool IsTradingHour()
{
   int hour = TimeHour(TimeCurrent());

   if(UseSessionPreset)
   {
      // Broker/server time based presets
      // Adjust later if needed for your broker
      if(SessionPreset == 1) // London
         return (hour >= 8 && hour < 13);

      if(SessionPreset == 2) // New York
         return (hour >= 13 && hour < 18);

      if(SessionPreset == 3) // London + New York
         return (hour >= 8 && hour < 18);

      if(SessionPreset == 4) // Custom
      {
         if(StartHour < EndHour)
            return (hour >= StartHour && hour < EndHour);

         return (hour >= StartHour || hour < EndHour);
      }

      return false;
   }

   if(StartHour < EndHour)
      return (hour >= StartHour && hour < EndHour);

   return (hour >= StartHour || hour < EndHour);
}

string GetSessionName()
{
   if(!UseSessionPreset)
      return "Manual";

   if(SessionPreset == 1) return "London";
   if(SessionPreset == 2) return "NewYork";
   if(SessionPreset == 3) return "London+NewYork";
   if(SessionPreset == 4) return "Custom";

   return "Unknown";
}

#endif