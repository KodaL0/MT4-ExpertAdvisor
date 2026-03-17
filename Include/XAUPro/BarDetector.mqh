#ifndef __XAU_BARDETECTOR_MQH__
#define __XAU_BARDETECTOR_MQH__

bool IsNewBar(datetime &lastBarTime)
{
   datetime currentBarTime = Time[0];
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

#endif