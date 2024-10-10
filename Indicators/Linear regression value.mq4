//--------------------------------------------------------------------------------------------------------------
#property strict
//--------------------------------------------------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_label1  "Linear regression value"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumSeaGreen
#property indicator_width1  2
#property indicator_label2  "Linear regression value down"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkOrange
#property indicator_width2  2
#property indicator_label3  "Linear regression value down"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDarkOrange
#property indicator_width3  2

//
//
//

input int                inpPeriod = 25;          // Period
input ENUM_APPLIED_PRICE inpPrice  = PRICE_CLOSE; // Price

//
//
//

double val[],valDown1[],valDown2[],valColor[];

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

int OnInit()
{
   IndicatorBuffers(4);
      SetIndexBuffer(0,val     ,INDICATOR_DATA);
      SetIndexBuffer(1,valDown1,INDICATOR_DATA);
      SetIndexBuffer(2,valDown2,INDICATOR_DATA);
      SetIndexBuffer(3,valColor,INDICATOR_CALCULATIONS);
  
      //
      //
      //
            
   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   int limit = (prev_calculated>0) ? rates_total-prev_calculated : rates_total-1;
  
   //
   //
   //

      if (valColor[limit]==-1) iCleanPoint(limit,rates_total,valDown1,valDown2);
      
      for (int i=limit, r=rates_total-i-1; i>=0 && !_StopFlag; i--,r++)
         {
            double _slope;
            double _intercept;
               val[i]      = iLinearRegression(iGetPrice(inpPrice,open[i],high[i],low[i],close[i]),inpPeriod,_slope,_intercept,r,rates_total);
               valColor[i] = (r>0) ? (val[i]>val[i+1]) ? 1 : (val[i]<val[i+1]) ? -1 : valColor[i+1] : 0;
          
               //
               //
               //
            
               if (valColor[i]==-1) iPlotPoint(i,rates_total,valDown1,valDown2,val); else valDown1[i] = valDown2[i] = EMPTY_VALUE;
         }
      
   //
   //
   //
        
   return(rates_total);
}

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

double iLinearRegression(double value, double period, double& _slope, double& _intercept, int r, int bars)
{
  struct sWorkStruct
      {
            struct sDataStruct
                  {
                        double value;
                        double sumY;
                        double sumXY;
                  };
            sDataStruct data[];
            int         dataSize;
            int         period;
            double      sumX;
            double      sumXX;
            double      divisor;
            
            //
            //
            //
                          
            sWorkStruct() : dataSize(-1), period(-1) { }
      };
   static sWorkStruct m_work;
                  if (m_work.dataSize <= bars) m_work.dataSize = ArrayResize(m_work.data,bars+500,2000);
                  
                  if (period<1) period = 1;
                  if (m_work.period != (int)period)
                        {
                           m_work.period  = (int)period;
                           m_work.sumX    = m_work.period * (m_work.period-1.0) / 2.0;
                           m_work.sumXX   = m_work.period * (m_work.period-1.0) * (2.0 * m_work.period - 1.0) / 6.0;
                           m_work.divisor = m_work.sumX * m_work.sumX - m_work.period * m_work.sumXX;
                              if (m_work.divisor)
                                  m_work.divisor = 1.0/m_work.divisor;
                        }

      //
      //---
      //

         m_work.data[r].value  = value;
        
            //
            //
            //
            
            if (r>=m_work.period)
                  {
                        m_work.data[r].sumY  = m_work.data[r-1].sumY  + value               - m_work.data[r-m_work.period].value;
                        m_work.data[r].sumXY = m_work.data[r-1].sumXY + m_work.data[r].sumY - m_work.data[r-m_work.period].value*(m_work.period-1.0) - value;
                  }
            else
                  {
                        m_work.data[r].sumY  = value;
                        m_work.data[r].sumXY = 0;

                           //
                           //
                           //
                          
                           for (int k=1; k<m_work.period && r>=k; k++)
                                 {
                                       m_work.data[r].sumY  +=   m_work.data[r-k].value;
                                       m_work.data[r].sumXY += k*m_work.data[r-k].value;
                                 }
                  }
        
         _slope     = (m_work.period*m_work.data[r].sumXY - m_work.sumX * m_work.data[r].sumY) * m_work.divisor;
         _intercept = (m_work.data[r].sumY - _slope * m_work.sumX) / (double)m_work.period ;
  
   //
   //
   //

   return(_intercept  + _slope*(m_work.period-1.0));
}

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

void iCleanPoint(int i, int bars,double& first[],double& second[])
{
   if (i>=bars-3) return;
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i]  != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
           first[i+1] = EMPTY_VALUE;
}

void iPlotPoint(int i, int bars,double& first[],double& second[],double& from[])
{
   if (i>=bars-2) return;
   if (first[i+1] == EMPTY_VALUE)
      if (first[i+2] == EMPTY_VALUE)
            { first[i]  = from[i]; first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
      else  { second[i] = from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else     { first[i]  = from[i];                          second[i] = EMPTY_VALUE; }
}

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

double iGetPrice(int tprice, double open, double high, const double low, const double close)
{
   switch (tprice)
      {
         case PRICE_CLOSE:     return(close);
         case PRICE_OPEN:      return(open);
         case PRICE_HIGH:      return(high);
         case PRICE_LOW:       return(low);
         case PRICE_MEDIAN:    return((high+low)/2.0);
         case PRICE_TYPICAL:   return((high+low+close)/3.0);
         case PRICE_WEIGHTED:  return((high+low+close+close)/4.0);
      }
   return(0);
}