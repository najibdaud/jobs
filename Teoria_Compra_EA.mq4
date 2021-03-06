//+------------------------------------------------------------------+
//|                                                       Teoria.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"

input double porcentagem_para_reversao = 60; //Porcentagem que irá reverter
extern int VelasMinima=2;
input int ModoTradeOrVisual=3; //1-Forex | 2-OB | 3-Visual
input string separador="O.B ===================================";
input int Aposta=1;
extern int TempoExpiracao=1;
input bool AtivarMartingaleBO=true;
input int MaxGalesMG=4; //Max=0 desativado | Max>0 ativado
extern double MultiplicaMG=2.0;
input string separador2="Forex ================================";
extern double Lote=0.01;
extern int StopLoss=200;
extern int TakeProfit=200;   
input bool AtivarMartingaleFX=true;
input double MaxGalesFX=0.16;
input double MultiplicaMGfx=2.0;
extern bool AtivarTraillingStop=false;
extern int TS=25;
input string separador3="======================================";
extern int Expert_ID = 1234; 

int ContVelas=0, ticket, arrow_i=0, _MagicNumber=0, dia_expiracao=0, mes_expiracao=0, ano_expiracao=0, n_conta=0;
double Porcentagem=0.0, won=1.0, loss=1.0, MartingaleBO=Aposta, MartingaleFX=Lote, identificador=0.0, pip;
bool travar_licenca=false,w;
datetime CurrentTimeStamp;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      //////////////////////////////////////// 
      n_conta = 2088976323;
      
      dia_expiracao = 30;
      mes_expiracao = 4;
      ano_expiracao = 2017;
      
      bool ContaDemo=true;  
      ////////////////////////////////////////
      
      if(AccountNumber()==n_conta && ContaDemo==false){
          Validacao();          
      }
      
      else if(AccountNumber()==n_conta && ContaDemo==true && IsDemo()==true){
          Validacao();
      }
      
      else{ travar_licenca=true; Alert("Você não possui licença para usar este EA"); } 
      
   CurrentTimeStamp = Time[0];
   TempoExpiracao=TempoExpiracao*60;
   
    int Period_ID = 0;
    switch ( Period() )
    {
        case PERIOD_MN1: Period_ID = 9; break;
        case PERIOD_W1:  Period_ID = 8; break;
        case PERIOD_D1:  Period_ID = 7; break;
        case PERIOD_H4:  Period_ID = 6; break;
        case PERIOD_H1:  Period_ID = 5; break;
        case PERIOD_M30: Period_ID = 4; break;
        case PERIOD_M15: Period_ID = 3; break;
        case PERIOD_M5:  Period_ID = 2; break;
        case PERIOD_M1:  Period_ID = 1; break;
    }
    _MagicNumber = Expert_ID * (10 + Period_ID);
    
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void start()
  {
//--- 
      if(travar_licenca==false){
      
      if(AtivarTraillingStop==true){
         Trailling();
      }
      
      // Verifica ordens que estão abertas 
      int order_c=0;
      for(int i=0; i<=OrdersTotal(); i++){
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
            if(OrderMagicNumber()==_MagicNumber && OrderSymbol()==Symbol()){
               order_c++;
            }
        }
      }
      
      if(CurrentTimeStamp != Time[0]){
            if(Close[1] > Open[1]){ // Fechamento for maior que abertura então conta + 1
               ContVelas++; 
            }else{
               ContVelas=0; // Senão, reinicia contador 
            } 
         CurrentTimeStamp = Time[0]; // Evita contar várias vezes a mesma vela  
      }
       
      // bug_fixed     
      if(ModoTradeOrVisual==1||ModoTradeOrVisual==2){ 
         if(ContVelas==(VelasMinima+1)) ContVelas=0;
      }
             
      if(ContVelas == VelasMinima && Porcentagem<porcentagem_para_reversao){
         //Se qnt de velas for maior q a qnt de velas mínima e porcentagem for menor que porcentagem para reversão
         //ContVelas=0; // Reinicia contador
         
         if(order_c==0){
            if(ModoTradeOrVisual==1){
               ticket=OrderSend(Symbol(),OP_BUY,MartingaleFX,Ask,0,Ask-StopLoss*Point,Ask+TakeProfit*Point,"",_MagicNumber,0,clrBlue);
               identificador=Open[0]+2;
            }
            
            if(ModoTradeOrVisual==2){
               ticket=OrderSend(Symbol(),OP_BUY,MartingaleBO,Ask,0,0,0,"BO exp:"+TempoExpiracao,_MagicNumber,0,clrBlue);
               identificador=Open[0]+2;
            }
         } 
      }
      
      else if(ContVelas == VelasMinima && Porcentagem>=porcentagem_para_reversao){ 
         //Se cont. velas for maior que a qnt de velas mínima e porcentagem for maior que porcentagem para reversão
         //ContVelas=0; // Reinicia contador
         
          if(order_c==0){
            if(ModoTradeOrVisual==1){
               ticket=OrderSend(Symbol(),OP_SELL,MartingaleFX,Bid,0,Bid+StopLoss*Point,Bid-TakeProfit*Point,"",_MagicNumber,0,clrRed);
               identificador=Open[0]+1;
            }
          
            if(ModoTradeOrVisual==2){
               ticket=OrderSend(Symbol(),OP_SELL,MartingaleBO,Bid,0,0,0,"BO exp:"+TempoExpiracao,_MagicNumber,0,clrRed);
               identificador=Open[0]+1;
            }
          } 
      }
      
      if(ModoTradeOrVisual==3){
        if(ContVelas > VelasMinima && Porcentagem<porcentagem_para_reversao){
            ContVelas=0;
            
            if(Close[1]>Open[1]){
               won++;
               arrow_i++;
               // Seta
               ObjectCreate("Up-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], Low[1]-20*Point);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 221);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrGreen);
               // Vitória
               ObjectCreate("1-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], High[1]+20*Point);
               ObjectSet("1-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 254);
               ObjectSet("1-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrGreen);
            }
            
            else if(Close[1]<Open[1]){
               loss++;
               arrow_i++;
               // Seta
               ObjectCreate("Up-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], Low[1]-20*Point);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 221);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrGreen);
               // Derrota
               ObjectCreate("1-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], High[1]+20*Point);
               ObjectSet("1-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 253);
               ObjectSet("1-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrRed);
            }
          }
          
          else if(ContVelas > VelasMinima && Porcentagem>=porcentagem_para_reversao){ 
            ContVelas=0;
             
            if(Close[1]<Open[1]){
               won++;
               arrow_i++;
               // Seta
               ObjectCreate("Down-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], High[1]+20*Point);
               ObjectSet("Down-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 222);
               ObjectSet("Down-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrRed); 
               // Vitória
               ObjectCreate("Up-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], Low[1]-20*Point);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 254);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrGreen);
            }
            
            else if(Close[1]>Open[1]){
               loss++;
               arrow_i++;
               // Vitória
               ObjectCreate("Down-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], High[1]+20*Point);
               ObjectSet("Down-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 222);
               ObjectSet("Down-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrRed);
               // Derrota
               ObjectCreate("Up-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], Low[1]-20*Point);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 253);
               ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrRed);
            }
          }
        }
 
      Porcentagem(); // Chama a função Porcentagem()
      Martingale(); // Chama a função Martingale() 
      // Mostra no canto superior as informações  
      if(ModoTradeOrVisual==2||ModoTradeOrVisual==3){
        Comment("Contador = "+ContVelas+" | MartingaleBO = "+MartingaleBO+" | Porcentagem = "+NormalizeDouble(Porcentagem,3)+"% | Wons = "+won+" / Losses = "+loss);
      } 
    }
//+------------------------------------------------------------------+^
}

double Porcentagem(){
   // Se for modo trade (O.B-2) conta a qnt de won e loss.
   // Verifica se mg está ativado para caso o último trade der loss multiplicar a aposta pelo MG.
   if(ModoTradeOrVisual==2){
      if((Open[1]+2)==identificador){
         identificador=0;
         if(Close[1]>Open[1]) won++;
         if(Close[1]<Open[1]) loss++;
      }
      
      else if((Open[1]+1)==identificador){
         identificador=0;
         if(Close[1]<Open[1]) won++;
         if(Close[1]>Open[1]) loss++;
      }
   }
  
   // Calcula a porcentagem de Wons
   Porcentagem=won/(won+loss)*100.0; 
   return(Porcentagem);
}

void Martingale(){
// Martingale
if(ModoTradeOrVisual==2&&AtivarMartingaleBO==true){
      for(int i=0; i<=OrdersHistoryTotal(); i++){    
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) && OrderSymbol()==Symbol() && OrderMagicNumber()==_MagicNumber && (OrderType()==OP_BUY||OrderType()==OP_SELL)){
            if(OrderProfit()<0){
               MartingaleBO=MartingaleBO*MultiplicaMG;
            }else if(OrderProfit()==0){
               MartingaleBO=OrderLots();
            }else if(OrderProfit()>0){
               MartingaleBO=Aposta;
            }
         }
      }
      
      // Limitador de gales (O.B)
      if(MaxGalesMG>0){
       if(Aposta==1){
           if(MartingaleBO>pow((Aposta*2),MaxGalesMG)){
               MartingaleBO=Aposta;
           }
       }else if(MartingaleBO>pow(Aposta,MaxGalesMG)){
               MartingaleBO=Aposta;
       }
     }
   }
//////////////////////////////////////////////////////////////////////
if(ModoTradeOrVisual==1&&AtivarMartingaleFX==true){
     for(int v=0; v<=OrdersHistoryTotal(); v++){   
         if(OrderSelect(v,SELECT_BY_POS,MODE_HISTORY) && OrderSymbol()==Symbol() && OrderMagicNumber()==_MagicNumber){
             if(OrderProfit()<0){
                MartingaleFX=MartingaleFX*MultiplicaMGfx;
                loss++;
             }else if(OrderProfit()==0){
                MartingaleFX=OrderLots();
             }else if(OrderProfit()>0){
                MartingaleFX=Lote;
                won++;
             }
         }
      }
     
      // Limitador de gales (FX)
      if(MaxGalesFX>0 && MartingaleFX>MaxGalesFX){
               MartingaleFX=Lote;
      }   
   } 
}

void Validacao(){
   dia_expiracao=dia_expiracao+1;
   
   if((dia_expiracao-Day())<=5 && (dia_expiracao-Day())>0 && mes_expiracao==Month() && ano_expiracao==Year()){
        Alert("Favor entrar em contato para renová-la.");
        Alert("Faltam "+((dia_expiracao)-Day())+" dia(s) para expirar sua licença."); 
   }
             
   if((dia_expiracao-Day())<=0 && (mes_expiracao-Month())<=0 && (ano_expiracao-Year())<=0){
         Alert("Desculpe, sua licença expirou.");
         travar_licenca=true;
   }
             
   if((dia_expiracao-Day())>=6 || mes_expiracao>=Month() || ano_expiracao>=Year()){
         if(mes_expiracao>Month() || ano_expiracao>Year()){
               int cal=0;
               mes_expiracao=(mes_expiracao-Month())*30;
               ano_expiracao=(ano_expiracao-Year())*360; 
               cal=(dia_expiracao-Day())+mes_expiracao+ano_expiracao;
               Alert("Faltam "+cal+" dia(s) para expirar sua licença."); 
         }else{
               Alert("Faltam "+((dia_expiracao)-Day())+" dia(s) para expirar sua licença."); 
         }
      }
   }

void Trailling(){
//--- 1.1. Define pip -----------------------------------------------------
   if(Digits==4 || Digits<=2) pip=Point;
   if(Digits==5 || Digits==3) pip=Point*10;

//--- 1.2. Trailing -------------------------------------------------------
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && TS>0 && OrderProfit()>0)
           {
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
           }
        }
     }
  }    
//--- 1.3. End of main function -------------------------------------------
