//+------------------------------------------------------------------+
//|                                                   stepbystep.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

struct set
{
   int    period;   
   double deviation;    
   double win;   
   double loss;   
   int    consecutive_wins;       
   int    consecutive_losses; 
   int    count_entries;
   double aptidao;
};

extern int     historical_bars      = 1000;   
extern int     period_start         = 20;
extern int     period_step          = 5;
extern int     period_stop          = 50;
extern double  deviation_start      = 2;
extern double  deviation_step       = 1;
extern double  deviation_stop       = 6; 

set populacao[];
int in=0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   for(int i=period_start; i<period_stop; i=i+period_step){
      for(double j=deviation_start; j<deviation_stop; j=j+deviation_step){
         Backtest(i,j);
         
         PrintFormat(" Epoca: "+IntegerToString(in)+" | "
                  +" Period: "+IntegerToString(populacao[in].period)
                  +" Deviation: "+DoubleToString(populacao[in].deviation,2)
                  +" Win: "+IntegerToString(populacao[in].win)
                  +" Loss: "+IntegerToString(populacao[in].loss)
                  +" Loss acumulado: "+IntegerToString(populacao[in].consecutive_losses)
                  +" Win acumulado: "+IntegerToString(populacao[in].consecutive_wins)
                  +" Entradas: "+IntegerToString(populacao[in].count_entries)
                  +" Aptidao: "+DoubleToString(populacao[in].aptidao,2));
         in++;
      }
   }
   
   PrintFormat(" ------------- Melhor aptidão --------------- ");
   int index = MelhorAptidao(populacao);
   PrintFormat("Period: "+IntegerToString(populacao[index].period)
                  +" Deviation: "+DoubleToString(populacao[index].deviation,2)
                  +" Win: "+IntegerToString(populacao[index].win)
                  +" Loss: "+IntegerToString(populacao[index].loss)
                  +" Loss acumulado: "+IntegerToString(populacao[index].consecutive_losses)
                  +" Win acumulado: "+IntegerToString(populacao[index].consecutive_wins)
                  +" Entradas: "+IntegerToString(populacao[index].count_entries)
                  +" Aptidao: "+DoubleToString(populacao[index].aptidao,2));
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

void Backtest(int p, double d){
      ArrayResize(populacao,ArraySize(populacao)+1);
      populacao[ArraySize(populacao)-1].period = p;
      populacao[ArraySize(populacao)-1].deviation = d;
      populacao[ArraySize(populacao)-1].aptidao=0;
      populacao[ArraySize(populacao)-1].consecutive_losses=0;
      populacao[ArraySize(populacao)-1].consecutive_wins=0;
      populacao[ArraySize(populacao)-1].count_entries=0;
      populacao[ArraySize(populacao)-1].loss=0;
      populacao[ArraySize(populacao)-1].win=0;
      
      int count_losses=0, count_wins=0;

      for(int i=historical_bars; i>=1; i--){
         double banda_inferior = iBands(NULL,0,populacao[in].period,populacao[in].deviation,0,PRICE_OPEN,MODE_LOWER,i+1);
         double banda_superior = iBands(NULL,0,populacao[in].period,populacao[in].deviation,0,PRICE_OPEN,MODE_UPPER,i+1);
         
         //realiza uma call
         if(Low[i+1] < banda_inferior && Close[i+1] > banda_inferior){
            if(Close[i] > Open[i]){
               populacao[in].win+=1;
               count_wins+=1;
               if(count_wins > populacao[in].consecutive_wins) populacao[in].consecutive_wins = count_wins;
               count_losses=0;
            }
            
            else if(Close[i] < Open[i]){
               populacao[in].loss+=1;
               count_losses+=1;
               if(count_losses > populacao[in].consecutive_losses) populacao[in].consecutive_losses = count_losses;
               count_wins=0;
            }
            
            populacao[in].count_entries+=1;
         }
         
         //realiza um put 
         else if(High[i+1] > banda_superior && Close[i+1] < banda_superior){
            if(Close[i] < Open[i]){
               populacao[in].win+=1;
               count_wins+=1;
               if(count_wins > populacao[in].consecutive_wins) populacao[in].consecutive_wins = count_wins;
               count_losses=0;
            }
            
            else if(Close[i] > Open[i]){
               populacao[in].loss+=1;
               count_losses+=1;
               if(count_losses > populacao[in].consecutive_losses) populacao[in].consecutive_losses = count_losses;
               count_wins=0;
            }
            
            populacao[in].count_entries+=1;
         }
         
      }

    //Avalia a aptidao do individuo
    double aptidao=populacao[in].win - populacao[in].loss - populacao[in].consecutive_losses;
    aptidao = aptidao > 0 ? aptidao + populacao[in].count_entries * 0.035 : aptidao - populacao[in].count_entries;
    populacao[in].aptidao=aptidao;
       
}

int MelhorAptidao(set& array[]){
   double melhor_aptidao = array[0].aptidao;
   int index=0;
   
   for(int i=0; i<ArraySize(array); i++){
      if(array[i].aptidao > melhor_aptidao){
         melhor_aptidao = array[i].aptidao;
         index=i;
      }
   }
   
   return index;
}
