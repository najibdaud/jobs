//+------------------------------------------------------------------+
//|                                                     signalOB.mq5 |
//|                                                        Jam Sávio |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Autor: Jam Sávio"

#define CALL 2
#define PUT -2

input  string              FILENAME                         =  "sinais.txt";      //Nome do Arquivo
input  double              VALOR_ENTRADA                    =  1;                 //Valor Entrada Padrão
input  bool                ATIVAR_MG                        =  false;             //Ativar Martingale
input  int                 QTD_MG                           =  2;                 //Qtd. Martingales
input  double              FATOR_MG                         =  2;                 //Fator Multiplicativo
input  double              VALOR_TP_DIARIO                  =  0;
input  double              VALOR_SL_DIARIO                  =  0;
input  int                 MAGIC_NUMBER                     =  12345;             //Magic Number
input  bool                ATIVAR_INDICADORES               =  false;             //Ativar Indicadores
input  string              SEPARATOR1                       =  "---Configurações do RSI---";
input  int                 MA_PERIOD_RSI                    =  14;
input  ENUM_APPLIED_PRICE  APPLIED_PRICE_RSI                =  PRICE_CLOSE;
input  string              SEPARATOR2                       =  "---Configurações do Stoch---";
input  int                 K_PERIOD                         =  5;
input  int                 D_PERIOD                         =  9;
input  int                 SLOWING                          =  6;
input  ENUM_MA_METHOD      MA_METHOD_STOCH                  =  MODE_SMA;
input  ENUM_STO_PRICE      PRICE_FIELD                      =  MODE_MAIN;  
input  string              SEPARATOR3                       =  "---Configurações do CCI---";
input  int                 MA_PERIOD_CCI                    =  14;
input  ENUM_APPLIED_PRICE  APPLIED_PRICE_CCI                =  PRICE_OPEN;

int    ticket[];
string sinais[][6], ticket_exp[], HORARIO_ATUAL, DATA_ATUAL;
double VALOR_MAXIMO_MG;
bool   ATINGIU_SL_DIARIO = false, ATINGIU_TP_DIARIO = false;

int OnInit()
  {
    //EXPIRAÇÃO DO EA
    string ExpiryDate = "2020.01.17 00:00";
    //AMARRAR O ACCOUNT ID
    int    NumeroConta = 0;
    //AMARRAR O BROKER
    string BrokerServer = "CLMarkets-Demo";
    //AMARRAR O ACCOUNT NAME
    string NomeConta = "0";
         
    if ((StrToInteger(ExpiryDate) == 0 || TimeCurrent() < StrToTime(ExpiryDate))
    && (NumeroConta == 0 || NumeroConta == AccountNumber())
    && (BrokerServer == "" || BrokerServer == AccountServer())
    && (NomeConta == "" || NomeConta == AccountName())){
    Print("entrou");
    EventSetMillisecondTimer(100);
    ResetLastError();
    int aux=1, index=0;
    int filehandle=FileOpen(FILENAME,FILE_READ|FILE_TXT|FILE_ANSI);
    if(filehandle!=INVALID_HANDLE){
      while(!FileIsEnding(filehandle)){
         string temp[];
         
         int str_size=FileReadInteger(filehandle,INT_VALUE);
         string conteudo_arquivo = FileReadString(filehandle,str_size);
         
         string sep=","; 
         ushort u_sep=StringGetCharacter(sep,0);
         int k=StringSplit(conteudo_arquivo,u_sep,temp);
         
         if(temp[2]==Symbol()){
            ArrayResize(sinais,aux);            
            sinais[index][0] = temp[0];
            sinais[index][1] = temp[1];
            sinais[index][2] = temp[2];
            sinais[index][3] = temp[3];
            sinais[index][4] = IntegerToString(StringToInteger(temp[4])*60);
            sinais[index][5] = "PENDENTE";
            aux++;
            index++;
         }
      }FileClose(filehandle); 
    }else PrintFormat("O arquivo não foi aberto com sucesso - (OnInit) Error ",GetLastError());  

   //martingale
   VALOR_MAXIMO_MG = VALOR_ENTRADA;
   for(int f=0; f<QTD_MG; f++) VALOR_MAXIMO_MG*=FATOR_MG;
   
   return(INIT_SUCCEEDED);
   
   }else{
      Alert("Sua licença é inválida ou expirou!\nFavor entrar em contato.");
      return(INIT_PARAMETERS_INCORRECT);
   }
  }

void OnDeinit(const int reason)
  {
//--- destruímos o temporizador no final do trabalho
   EventKillTimer();
  }
  
void OnTimer()
  {
      if(VALOR_SL_DIARIO != 0 || VALOR_TP_DIARIO != 0) CheckStops();
      
      if(ATINGIU_SL_DIARIO == false && ATINGIU_TP_DIARIO == false){
      
         if(ATIVAR_MG==true) CheckLastOrder();
         
         for(int i=0; i<ArraySize(sinais)/6; i++){
              if(sinais[i][2] == Symbol() && sinais[i][5] == "PENDENTE"){
                  RefreshTime();
                  if(sinais[i][0] == DATA_ATUAL && sinais[i][1] == HORARIO_ATUAL){
                     if(sinais[i][3] == "CALL" && ATIVAR_INDICADORES == false){
                        Alert("entrou");
                        RefreshRates();
                        ArrayResize(ticket,ArraySize(ticket)+1);
                        ticket[ArraySize(ticket)-1] = OrderSend(Symbol(),OP_BUY,VALOR_ENTRADA,Close[0],0,0,0,"BO exp:"+sinais[i][4],MAGIC_NUMBER,0,clrGreen);
                        ArrayResize(ticket_exp,ArraySize(ticket_exp)+1);
                        ticket_exp[ArraySize(ticket_exp)-1] = "BO exp:"+sinais[i][4];
                        sinais[i][5] = "EXECUTOU";
                        Registrar(i);
                     }
                     
                     else if(sinais[i][3] == "CALL" && ATIVAR_INDICADORES == true && CheckConfluenceIndicators() >= CALL){
                        Alert("entrou");
                        RefreshRates();
                        ArrayResize(ticket,ArraySize(ticket)+1);
                        ticket[ArraySize(ticket)-1] = OrderSend(Symbol(),OP_BUY,VALOR_ENTRADA,Close[0],0,0,0,"BO exp:"+sinais[i][4],MAGIC_NUMBER,0,clrGreen);
                        ArrayResize(ticket_exp,ArraySize(ticket_exp)+1);
                        ticket_exp[ArraySize(ticket_exp)-1] = "BO exp:"+sinais[i][4];
                        sinais[i][5] = "EXECUTOU";
                        Registrar(i);
                     }
                     
                     else if(sinais[i][3] == "PUT" && ATIVAR_INDICADORES == false){
                        Alert("entrou");
                        RefreshRates();
                        ArrayResize(ticket,ArraySize(ticket)+1);
                        ticket[ArraySize(ticket)-1] = OrderSend(Symbol(),OP_SELL,VALOR_ENTRADA,Close[0],0,0,0,"BO exp:"+sinais[i][4],MAGIC_NUMBER,0,clrRed);
                        ArrayResize(ticket_exp,ArraySize(ticket_exp)+1);
                        ticket_exp[ArraySize(ticket_exp)-1] = "BO exp:"+sinais[i][4];
                        sinais[i][5] = "EXECUTOU";
                        Registrar(i);
                     }
                     
                     else if(sinais[i][3] == "PUT" && ATIVAR_INDICADORES == true && CheckConfluenceIndicators() <= PUT){
                        Alert("entrou");
                        RefreshRates();
                        ArrayResize(ticket,ArraySize(ticket)+1);
                        ticket[ArraySize(ticket)-1] = OrderSend(Symbol(),OP_SELL,VALOR_ENTRADA,Close[0],0,0,0,"BO exp:"+sinais[i][4],MAGIC_NUMBER,0,clrRed);
                        ArrayResize(ticket_exp,ArraySize(ticket_exp)+1);
                        ticket_exp[ArraySize(ticket_exp)-1] = "BO exp:"+sinais[i][4];
                        sinais[i][5] = "EXECUTOU";
                        Registrar(i);
                     }
                  }
              }  
          }
      }
  }

void OnTick(){
   if(ATIVAR_INDICADORES == true){
       int signal = CheckConfluenceIndicators();
       if(signal>=CALL) Comment("Indicators signal = CALL");
       else if(signal<=PUT) Comment("Indicators signal = PUT");
       else if((signal < 0 && signal>PUT) || (signal > 0 && signal < 2) || signal==0) Comment("Indicators signal = NEUTRAL");
   }
}

int CheckConfluenceIndicators(){
   int signal=0;

   double rsi     =     iRSI(NULL,0,MA_PERIOD_RSI,APPLIED_PRICE_RSI,0);
   double stoch   =     iStochastic(NULL,0,K_PERIOD,D_PERIOD,SLOWING,MA_METHOD_STOCH,0,PRICE_FIELD,0);
   double cci     =     iCCI(NULL,0,MA_PERIOD_CCI,APPLIED_PRICE_CCI,0);
   
   //rsi
   if(rsi < 45) signal-=1;
   else if(rsi > 55) signal+=1;
   
   //stoch
   if(stoch < 45) signal-=1;
   else if(stoch > 55) signal+=1;
   
   //cci
   if(cci < -25) signal-=1;
   else if(cci > 25) signal+=1;
   
   return signal;
}


void CheckLastOrder(){  
  for(int i=OrdersHistoryTotal(); i>=0; i--){ 
      for(int j=0; j<ArraySize(ticket); j++){
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) == true && OrderTicket()==ticket[j]){
            if(OrderProfit()<0 && OrderLots()*FATOR_MG<=VALOR_MAXIMO_MG){
                  if(OrderType()==OP_BUY){
                     RefreshRates();
                     ticket[j] = OrderSend(Symbol(),OP_BUY,OrderLots()*FATOR_MG,Close[0],0,0,0,ticket_exp[j],MAGIC_NUMBER,0,clrYellow);
                  }
                  else if(OrderType()==OP_SELL){
                     RefreshRates();
                     ticket[j] = OrderSend(Symbol(),OP_SELL,OrderLots()*FATOR_MG,Close[0],0,0,0,ticket_exp[j],MAGIC_NUMBER,0,clrYellow); 
                  }  
            }
      
            else if(OrderLots()*FATOR_MG>VALOR_MAXIMO_MG){
               TicketRemove(ticket,j);
               TicketExpRemove(ticket_exp,j);
            }
            
            else if(OrderProfit()>0){
               TicketRemove(ticket,j);
               TicketExpRemove(ticket_exp,j);
            }
         }
      }
   } 
}

void CheckStops(){
   double profit = 0;
   for(int i=OrdersHistoryTotal(); i>=0; i--){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true){
         if(TimeToStr(TimeCurrent(),TIME_DATE) == TimeToStr(OrderCloseTime(),TIME_DATE)){
            profit += OrderProfit();
         }
      }
   }  
      
   if(VALOR_SL_DIARIO != 0){
      if(profit <= VALOR_SL_DIARIO) ATINGIU_SL_DIARIO = true; 
      else ATINGIU_SL_DIARIO = false;
   }   
   
   if(VALOR_TP_DIARIO != 0){
      if(profit >= VALOR_TP_DIARIO) ATINGIU_TP_DIARIO = true; 
      else ATINGIU_TP_DIARIO = false;
   }
}

void RefreshTime(){
    MqlDateTime time;
    TimeLocal(time);
   
    if(time.hour < 10 || time.hour == 0){
      HORARIO_ATUAL = "0"+IntegerToString(time.hour);
    }else{
      HORARIO_ATUAL = IntegerToString(time.hour);
    }
    
    if(time.min < 10 || time.min == 0){
      HORARIO_ATUAL = HORARIO_ATUAL+":0"+IntegerToString(time.min);
    }else{
      HORARIO_ATUAL = HORARIO_ATUAL+":"+IntegerToString(time.min);
    }
    
    if(time.day < 10){
      DATA_ATUAL = "0"+IntegerToString(time.day);
    }else{
      DATA_ATUAL = IntegerToString(time.day);
    }
    
    if(time.mon < 10){
      DATA_ATUAL = DATA_ATUAL+"/0"+IntegerToString(time.mon);
    }else{
      DATA_ATUAL = DATA_ATUAL+"/"+IntegerToString(time.mon);
    }
    
    DATA_ATUAL = DATA_ATUAL+"/"+IntegerToString(time.year);
}
  
void Registrar(int index){
   string sinal =  sinais[index][0]+","
                   +sinais[index][1]+","
                   +sinais[index][2]+","
                   +sinais[index][3]+","
                   +sinais[index][4]+","
                   +sinais[index][5];
   int fileHandle = FileOpen("sinais_executados.txt", FILE_READ|FILE_WRITE|FILE_TXT);
   FileSeek(fileHandle, 0, SEEK_END);
   FileWriteString(fileHandle,"\n"+sinal);  
   FileClose(fileHandle); 
}

void TicketRemove(int& array[], int index){
   int temp_array[];
   
   ArrayCopy(temp_array,array,0,0,index);
   ArrayCopy(temp_array,array,index,index+1,ArraySize(array)-1);
   ArrayFree(array);
   ArrayCopy(array,temp_array,0,0);
}

void TicketExpRemove(string& array[], int index){
   int temp_array[];
   
   ArrayCopy(temp_array,array,0,0,index);
   ArrayCopy(temp_array,array,index,index+1,ArraySize(array)-1);
   ArrayFree(array);
   ArrayCopy(array,temp_array,0,0);
}