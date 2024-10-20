//+-----------------------------------------------------------------+
//|                        Color Stochastic Multitime Frame V2.mq4 	|
//|                                                            		|
//+-----------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers   6
#property indicator_color1  Yellow
#property indicator_color2  DimGray
#property indicator_color3  Green
#property indicator_color4  DeepSkyBlue
#property indicator_color5  Red
#property indicator_color6  Red
#property indicator_style1  STYLE_DOT
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_minimum   0
#property indicator_maximum 100
#property indicator_level1	80
#property indicator_level2	20
#property indicator_level3	50
//
//
extern string TimeFrame             = "current time frame";
extern int    KPeriod               =  70;
extern int    Slowing               =  15;
extern int    DPeriod               =  10;
extern int    MAMethod              =   3;
extern int    PriceField            =   0;
extern int    overBought            =  80;
extern int    overSold              =  20;
extern bool   Interpolate           = true;
extern bool   showLevels            = false;
extern bool   showArrows            = false;
extern bool   showArrowsOnZoneEnter = false;
extern bool   showArrowsOnZoneExit  = false;
extern string arrowsIdentifier      = "Color stochastic";
extern color  arrowsOBColor         = White;
extern color  arrowsOSColor         = Red;

//
//
extern bool   alertsOn          = false;
extern bool   alertsOnZoneEnter = false;
extern bool   alertsOnZoneExit  = false;
extern bool   alertsOnCurrent   = false;
extern bool   alertsMessage     = false;
extern bool   alertsSound       = false;
extern bool   alertsEmail       = false;

//
//

double KFull[];
double DFull[];
double Uppera[];
double Upperb[];
double Lowera[];
double Lowerb[];
double trend[];

//
//
//
int    timeFrame;
string IndicatorFileName;
bool   ReturningBars;

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
int init()
{
   for (int i=0; i<indicator_buffers; i++) SetIndexStyle(i,DRAW_LINE);
   IndicatorBuffers(7);
      SetIndexBuffer(0,DFull);  SetIndexLabel(1,"Stochastic");
      SetIndexBuffer(1,KFull);  
      SetIndexBuffer(2,Uppera); SetIndexLabel(2,NULL);
      SetIndexBuffer(3,Upperb); SetIndexLabel(3,NULL);
      SetIndexBuffer(4,Lowera); SetIndexLabel(4,NULL);
      SetIndexBuffer(5,Lowerb); SetIndexLabel(5,NULL);
      SetIndexBuffer(6,trend);
      
         
         IndicatorFileName = WindowExpertName();
         ReturningBars     = (TimeFrame=="returnBars");   if (ReturningBars)  { showArrows=False; return(0); }
         timeFrame         = stringToTimeFrame(TimeFrame);
      
         
      DPeriod = MathMax(DPeriod,1);
      if (DPeriod==1) {
            SetIndexStyle(0,DRAW_NONE);
            SetIndexLabel(0,NULL);
          }
      else {
            SetIndexStyle(0,DRAW_LINE); 
            SetIndexLabel(0,"Signal");
         }               
      /*
      if (showLevels)
           { SetLevelValue(0,overBought); SetLevelValue(1,overSold); }
      else { SetLevelValue(0,EMPTY);      SetLevelValue(1,EMPTY);     }
        */ 
 
   string shortName = "Stochastic "+timeFrameToString(timeFrame)+" ("+KPeriod+","+DPeriod+","+Slowing+","+maDescription(MAMethod)+","+priceDescription(PriceField);
         if (overBought < overSold) overBought = overSold;
         if (overBought < 100)      shortName  = shortName+","+overBought;
         if (overSold   >   0)      shortName  = shortName+","+overSold;
   IndicatorShortName(shortName+")");
   return(0);
}

//
//
//
//
//

int deinit()
{
   if (showArrows) deleteArrows();
   return(0);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
int start()
{
   int counted_bars=IndicatorCounted();
   int i,limit;

   if(counted_bars < 0)   return(-1);
   if(counted_bars > 0)   counted_bars--;
           limit = MathMin(Bars-counted_bars,Bars-1);
           if (ReturningBars)  { KFull[0] = limit+1; return(0); }
           if (timeFrame > Period()) limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,IndicatorFileName,"returnBars",0,0)*timeFrame/Period()));

   //
   //
   if (trend[limit]== 1) CleanPoint(limit,Uppera,Upperb);
   if (trend[limit]==-1) CleanPoint(limit,Lowera,Lowerb);
   
   for(i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         KFull[i] = iStochastic(NULL,timeFrame,KPeriod,DPeriod,Slowing,MAMethod,PriceField,MODE_MAIN,y);
         DFull[i] = iStochastic(NULL,timeFrame,KPeriod,DPeriod,Slowing,MAMethod,PriceField,MODE_SIGNAL,y);
         trend[i] = trend[i+1];           
            
            
            if (KFull[i] > overSold   && KFull[i] > DFull[i]) trend[i] =   1;
            if (KFull[i] < overBought && KFull[i] < DFull[i]) trend[i] =  -1;
            
            if (KFull[i] < overSold && KFull[i] > DFull[i]) trend[i]   =  0;
            if (KFull[i] > overBought && KFull[i] < DFull[i]) trend[i] =  0;            
            //if (KFull[i] < overBought && KFull[i] > overSold) trend[i] =  0;
            //if (KFull[i] > overBought)                        trend[i] =  1;
            //if (KFull[i] < overSold  )                        trend[i] = -1;

         //
         //
         if (timeFrame <= Period() || y==iBarShift(NULL,timeFrame,Time[i-1])) continue;
         if (!Interpolate) continue;

         //
         //
         //
         //
         //

         datetime time = iTime(NULL,timeFrame,y);
            for(int n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
            double factor = 1.0 / n;
            for(int k = 1; k < n; k++)
            {
               KFull[i+k] = k*factor*KFull[i+n] + (1.0-k*factor)*KFull[i];
               DFull[i+k] = k*factor*DFull[i+n] + (1.0-k*factor)*DFull[i];
            }
   }
   
   //
   //
   //
   //
   //
   
   for(i=limit; i>=0; i--)
   {
      Uppera[i] = EMPTY_VALUE;
      Upperb[i] = EMPTY_VALUE;
      Lowera[i] = EMPTY_VALUE;
      Lowerb[i] = EMPTY_VALUE;
         if (trend[i]== 1) PlotPoint(i,Uppera,Upperb,KFull);
         if (trend[i]==-1) PlotPoint(i,Lowera,Lowerb,KFull);

      //
      //
            
      if (showArrows)
      {
         deleteArrow(Time[i]);
         if (trend[i]!=trend[i+1])
         {
            if (showArrowsOnZoneEnter && trend[i]   == 1)                 drawArrow(i,arrowsOBColor,241,false);
            if (showArrowsOnZoneEnter && trend[i]   ==-1)                 drawArrow(i,arrowsOSColor,242,true);
            if (showArrowsOnZoneExit  && trend[i+1] == 1 && trend[i]!=-1) drawArrow(i,arrowsOBColor,242,true);
            if (showArrowsOnZoneExit  && trend[i+1] ==-1 && trend[i]!= 1) drawArrow(i,arrowsOSColor,241,False);
         }
      }               
   }      
   
   //
   //
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar));
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (alertsOnZoneEnter && trend[whichBar]   == 1)                        doAlert(whichBar,DoubleToStr(overBought,2)+" crossed up");
         if (alertsOnZoneEnter && trend[whichBar]   ==-1)                        doAlert(whichBar,DoubleToStr(overSold  ,2)+" crossed down");
         if (alertsOnZoneExit  && trend[whichBar+1] == 1 && trend[whichBar]!=-1) doAlert(whichBar,DoubleToStr(overBought,2)+" crossed dow");
         if (alertsOnZoneExit  && trend[whichBar+1] ==-1 && trend[whichBar]!= 1) doAlert(whichBar,DoubleToStr(overSold  ,2)+" crossed up");
      }         
   }
   return(0);
}


//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+Time[i];
   double gap  = 6.0*iATR(NULL,0,20,i)/4.0;   
         
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i]+gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i] -gap);
}

void deleteArrows()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
}
void deleteArrow(datetime time)
{
   string lookFor = arrowsIdentifier+":"+time; ObjectDelete(lookFor);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," stochastic level ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"Color stochastic "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
      {
         if (first[i+2] == EMPTY_VALUE) {
                first[i]   = from[i];
                first[i+1] = from[i+1];
                second[i]  = EMPTY_VALUE;
            }
         else {
                second[i]   =  from[i];
                second[i+1] =  from[i+1];
                first[i]    = EMPTY_VALUE;
            }
      }
   else
      {
         first[i]  = from[i];
         second[i] = EMPTY_VALUE;
      }
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
string priceDescription(int mode)
{
   string answer;
   switch(mode)
   {
      case 0:  answer = "Low/High"    ; break; 
      case 1:  answer = "Close/Close" ; break;
      default: answer = "Invalid price field requested";
                                    Alert(answer);
   }
   return(answer);
}
string maDescription(int mode)
{
   string answer;
   switch(mode)
   {
      case MODE_SMA:  answer = "SMA"  ; break; 
      case MODE_EMA:  answer = "EMA"  ; break;
      case MODE_SMMA: answer = "SMMA" ; break;
      case MODE_LWMA: answer = "LWMA" ; break;
      default:        answer = "Invalid MA mode requested";
                                    Alert(answer);
   }
   return(answer);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

int stringToTimeFrame(string tfs)
{
   tfs = StringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

string StringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int tchar = StringGetChar(s, length);
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                     s = StringSetChar(s, length, tchar - 32);
         else if(tchar > -33 && tchar < 0)
                     s = StringSetChar(s, length, tchar + 224);
   }
   return(s);
}