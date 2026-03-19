#ifndef __XAU_SPREADFILTER_MQH__
#define __XAU_SPREADFILTER_MQH__

double g_spreadHistory[100];
int g_spreadIndex = 0;

void UpdateSpreadHistory()
{
   int spread = (int)((Ask - Bid) / Point);

   g_spreadHistory[g_spreadIndex] = spread;
   g_spreadIndex++;

   if(g_spreadIndex >= SpreadAveragePeriod)
      g_spreadIndex = 0;
}

double GetAverageSpread()
{
   double total = 0;
   int count = 0;

   for(int i = 0; i < SpreadAveragePeriod; i++)
   {
      if(g_spreadHistory[i] > 0)
      {
         total += g_spreadHistory[i];
         count++;
      }
   }

   if(count == 0)
      return 0;

   return total / count;
}

bool IsSpreadSpike()
{
   if(!UseSpreadSpikeProtection)
      return false;

   int currentSpread = (int)((Ask - Bid) / Point);
   double avgSpread = GetAverageSpread();

   if(avgSpread <= 0)
      return false;

   if(currentSpread > avgSpread * SpreadSpikeMultiplier)
      return true;

   return false;
}

#endif