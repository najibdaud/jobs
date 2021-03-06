//+------------------------------------------------------------------+
//|                                                  S3_modified.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "2.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 clrMagenta
#property indicator_color2 clrMagenta
#property indicator_color3 clrLawnGreen
#property indicator_color4 clrRed

#include <mql4-mysql.mqh>

#import "Kernel32.dll"
bool GetVolumeInformationW(string,string,uint,uint&[],uint,uint,string,uint);
#import

#define CALL 1
#define PUT -1

struct backtest
{  
   double win;   
   double loss;   
   int consecutive_wins;       
   int consecutive_losses; 
   int count_entries;
};

//--- input parameter
input color    textColor        = clrWhite;
input string   import_indicator = "S3";
input int      qtd_candles      = 1440;
input int      block_candles    = 2;
input string   usuario          = "";
input string   senha            = "";

//--- host parameter
string  host     = "remotemysql.com";
string  user     = "REsTejG9az";
string  pass     = "NallszJS4O";
string  dbName   = "REsTejG9az";
int     port     = 3306;
int     socket   = 0;
int     client   = 0;

backtest info;
static datetime prevTime;

int      count_losses = 0, //serve para contabilizar os wins e losses consecutivos
         count_wins = 0, 
         cont_sinais = -1; //serve para filtrar os sinais falsos pela qtd de candles
//int      bars = qtd_candles;
bool     acesso_liberado = false, 
         goodConnect = false, 
         mode_backtest = false;
         //atualizou = false;
int      operacao[2],
         bars = qtd_candles,
         contador = 0,
         uninit_reason;
         //operacao2[2],
         //operacao3[2];

//--- buffers
double ganhou[], perdeu[], up[], down[];

int init()
  {
   mode_backtest = IsTesting();
   string get_serial = GetSerialKey();
   if(mode_backtest!=true){ //somente fazer login caso não seja um backtest
      if((usuario != "" && senha != "") || get_serial!=""){
         int dbConnectId = 0;
         
         goodConnect = init_MySQL(dbConnectId, host, user, pass, dbName, port, socket, client);
         if ( !goodConnect ) return (1);
         
         if(usuario != "" && senha != ""){
               string query = "SELECT usuario,serial_key FROM usuarios WHERE `usuario` = \'"+usuario+"\' AND `senha` = \'"+senha+"\'"; 
               
               string data[][3];
               int result = MySQL_FetchArray(dbConnectId, query, data);
               
               if (result > 0){
                  string usuario_bd = data[0][0];
                  string serial_key = data[0][1];
                  
                  if(usuario_bd == usuario && serial_key == VolumeSerialNumber()){ 
                     acesso_liberado = true;
                     Alert("Acesso liberado. Obrigado!");
                     if(get_serial=="") GravarSerialKey(VolumeSerialNumber());
                  }
            
                  else if(usuario_bd == usuario && serial_key == ""){
                     string insertQuery  = "UPDATE `usuarios` SET `serial_key` = \'"+VolumeSerialNumber()+"\' WHERE `usuario` = \'"+usuario+"\'";
                     
                      if ( MySQL_Query(dbConnectId, insertQuery) ) {
                        acesso_liberado = true;
                        Alert("Acesso liberado. Obrigado!");
                        GravarSerialKey(VolumeSerialNumber());
                      }
                  }
                  
                  else if(usuario_bd == usuario && serial_key!=VolumeSerialNumber()){
                     Alert("Não é possível utilizar este usuário em outro computador.");
                  }
                 
               }else{ Alert("Usuário ou senha incorretos.\nTente novamente."); }
         }else{
             string query = "SELECT usuario FROM usuarios WHERE `serial_key` = \'"+get_serial+"\'";
             
             string data[][1];
             int result = MySQL_FetchArray(dbConnectId, query, data);
             
             if (result > 0){
                  acesso_liberado = true;
                  Alert("Autenticação validada, ",data[0][0],".\nAcesso liberado. Obrigado!");
             }else{
                  Alert("Não foi possível validar sua conta automaticamente.\nFavor fornecer os dados de acesso manualmente.");
             } 
         }
         deinit_MySQL(dbConnectId);  
      }else{
         Alert("Favor informar (nos parâmetros) um usuário e senha\npara liberar o acesso ao indicador.");
      }
   }
   
//--- indicator buffers mapping
   SetIndexStyle(0,DRAW_ARROW,NULL,2);
   SetIndexArrow(0,221); //221 for up arrow
   SetIndexBuffer(0,up);
   SetIndexLabel(0,"UP S3");
   
   SetIndexStyle(1,DRAW_ARROW,NULL,2);
   SetIndexArrow(1,222); //222 for down arrow
   SetIndexBuffer(1,down);
   SetIndexLabel(1,"DOWN S3");
   
   SetIndexStyle(2,DRAW_ARROW,NULL,2);
   SetIndexArrow(2,254); 
   SetIndexBuffer(2,ganhou);
   SetIndexLabel(2,"WIN");
   
   SetIndexStyle(3,DRAW_ARROW,NULL,2);
   SetIndexArrow(3,253);
   SetIndexBuffer(3,perdeu);
   SetIndexLabel(3,"LOSS");
//---

   //inicializa o placar
   //AtualizarPlacar();
   info.consecutive_losses=0;
   info.consecutive_wins=0;
   info.count_entries=0;
   info.loss=0;
   info.win=0;
   
   return(0);
  }

int deinit(const int reason){
   //caso o indicador seja removido, isto irá remover o placar
   ObjectDelete("consecutive_losses");
   ObjectDelete("consecutive_wins");
   ObjectDelete("count_entries");
   ObjectDelete("draw");        
   ObjectDelete("losses");  
   ObjectDelete("wins");  
   ObjectDelete("wins_rate");
   ArrayFree(ganhou);
   ArrayFree(perdeu);
   ArrayFree(up);
   ArrayFree(down);
   uninit_reason=reason;
   return(0);
}
  
int start(){      
     if(mode_backtest==true || acesso_liberado == true){
        /*if(mode_backtest!=true && atualizou == false){
            AtualizarSinais();
            atualizou=true;
        }*/
        
        for(int pos=bars; pos>0; pos--){
                  double up_arrow = iCustom(NULL,0,import_indicator,0,pos);
                  double down_arrow = iCustom(NULL,0,import_indicator,1,pos);
                  
                  if(up_arrow != NULL){
                     up[pos] = NormalizeDouble(Low[pos]-20*Point,Digits);
                     realizar_backtest(CALL,pos-1);
                  }
                
                   //espelho do anterior, só que para put
                   if(down_arrow != 0){
                        cont_sinais=0; 
                        down[pos] = NormalizeDouble(High[pos]+20*Point,Digits);
                        realizar_backtest(PUT,pos-1);
                   }
         }bars=0;
               
        if(prevTime!=Time[0]){
               double up_arrow = iCustom(NULL,0,import_indicator,0,0);
               double down_arrow = iCustom(NULL,0,import_indicator,1,0);
               
               //call
               if(up_arrow != NULL){
                     // aqui é o bypass das entradas
                     // atenção a variável cont_sinais, pois ela não pode resetar caso o usuário feche o gráfico
                     // e caso isso ocorra, ela irá mostrar entradas incongruentes fora do range do bypass
                     if(cont_sinais==-1 || cont_sinais==block_candles){
                        cont_sinais=0; //reseta o cont_sinais
                        up[0] = NormalizeDouble(Low[0]-20*Point,Digits);
                        realizar_backtest(operacao[0],iBarShift(NULL,0,operacao[1])-1);
                        //---------- atenção aqui
                        operacao[0] = CALL; //define o tipo da entrada
                        operacao[1] = Time[0]; //guarda o momento que houve a entrada
                        //---------- isto também não pode resetar, pois é necessário para contabilizar a última entrada caso
                        // o usuário feche o gráfico
                        
                        //gravar os sinais e o placar para recuperar quando fechar o mt4
                        //if(mode_backtest!=true) GravarAtualizacaoSinais(operacao[1],CALL,Symbol(),Period());
                     }else{
                        Alert("entrou");
                        cont_sinais++;
                        if(iBarShift(NULL,0,operacao[1]) == 1) Alert("Possível aumento na volatilidade...");
                        //GravarContSinais(cont_sinais);
                     }
                     prevTime=Time[0]; //evitar que fique dando vários sinais na mesma vela
                }
                
                //espelho do anterior, só que para put
                if(down_arrow != 0){
                     if(cont_sinais==-1 || cont_sinais==block_candles){
                        cont_sinais=0; 
                        down[0] = NormalizeDouble(High[0]+20*Point,Digits);
                        realizar_backtest(operacao[0],iBarShift(NULL,0,operacao[1])-1);
                        operacao[0] = PUT;
                        operacao[1] = Time[0];

                        //if(mode_backtest!=true) GravarAtualizacaoSinais(operacao[1],PUT,Symbol(),Period());
                     }else{
                        cont_sinais++;
                        if(iBarShift(NULL,0,operacao[1]) == 1) Alert("Possível aumento na volatilidade...");
                        //GravarContSinais(cont_sinais);
                    }
                    prevTime=Time[0];
                }    
         }  
         
         Painel();            
     }        
   return(0);
}

//serve para plotar os 'wingdings' e contabilizar os wins/losses
void realizar_backtest(int op, int i){
      if(op==CALL && Close[i] > Open[i]){
         info.win++;
         info.count_entries++;
         count_wins++;
         if(count_wins > info.consecutive_wins) info.consecutive_wins = count_wins;
         count_losses=0;
         ganhou[i] = NormalizeDouble(High[i]+40*Point,Digits);
      }
      
      else if(op==CALL && Close[i] < Open[i]){
         info.loss++;
         info.count_entries++;
         count_losses++;
         if(count_losses > info.consecutive_losses) info.consecutive_losses = count_losses;
         count_wins=0;
         perdeu[i] = NormalizeDouble(High[i]+40*Point,Digits);
      }
      
      else if(op==CALL && Close[i] == Open[i]) info.count_entries++;
      
      //--
      
      if(op==PUT && Close[i] < Open[i]){
         info.win++;
         info.count_entries++;
         count_wins++;
         if(count_wins > info.consecutive_wins) info.consecutive_wins = count_wins;
         count_losses=0;
         ganhou[i] = NormalizeDouble(Low[i]-40*Point,Digits);
      }
      
      else if(op==PUT && Close[i] > Open[i]){
         info.loss++;
         info.count_entries++;
         count_losses++;
         if(count_losses > info.consecutive_losses) info.consecutive_losses = count_losses;
         count_wins=0;
         perdeu[i] = NormalizeDouble(Low[i]-40*Point,Digits);
      }
      
      else if(op==PUT && Close[i] == Open[i]) info.count_entries++;
}

//serve para desenhar o placar
void CreateTextLable
(string TextLableName, string Text, int TextSize, string FontName, color TextColor, int TextCorner, int X, int Y)
{
//---
   ObjectCreate(TextLableName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(TextLableName, OBJPROP_CORNER, 1);
   ObjectSet(TextLableName, OBJPROP_XDISTANCE, X);
   ObjectSet(TextLableName, OBJPROP_YDISTANCE, Y);
   ObjectSetText(TextLableName,Text,TextSize,FontName,TextColor);
}

//serve para mostrar as estatísticas (win, loss)
void Painel()
{
   int font_size=8;
   int font_x=20;
   string font_type="Time New Roman";
   double rate;
   if(info.win != 0) rate = (info.win/(info.win+info.loss))*100;
   else rate = 0;
   string wins = "WIN: "+DoubleToString(info.win,0);
   CreateTextLable("wins",wins,font_size,font_type,textColor,0,font_x,10);
   string losses = "LOSS: "+DoubleToString(info.loss,0);
   CreateTextLable("losses",losses,font_size,font_type,textColor,0,font_x,30);
   string consecutive_wins = "CONSECUTIVE WINS: "+IntegerToString(info.consecutive_wins);
   CreateTextLable("consecutive_wins",consecutive_wins,font_size,font_type,textColor,0,font_x,50);
   string consecutive_losses = "CONSECUTIVE LOSSES: "+IntegerToString(info.consecutive_losses);
   CreateTextLable("consecutive_losses",consecutive_losses,font_size,font_type,textColor,0,font_x,70);
   string count_entries = "COUNT ENTRIES: "+IntegerToString(info.count_entries);
   CreateTextLable("count_entries",count_entries,font_size,font_type,textColor,0,font_x,90);
   string wins_rate = "WIN RATE: "+DoubleToString(rate,2)+"%";
   CreateTextLable("wins_rate",wins_rate,font_size,font_type,textColor,0,font_x,110);
}

//serve para salvar o unique id de cada usuário
string VolumeSerialNumber()
  {
//---
   string res="";
//---
   string RootPath=StringSubstr(TerminalInfoString(TERMINAL_COMMONDATA_PATH),0,1)+":\\";
   string VolumeName,SystemName;
   uint VolumeSerialNumber[1],Length=0,Flags=0;
//---
   if(!GetVolumeInformationW(RootPath,VolumeName,StringLen(VolumeName),VolumeSerialNumber,Length,Flags,SystemName,StringLen(SystemName)))
     {
      res="XXXX-XXXX";
      Print("Failed to receive VSN !");
     }
   else
     {
      //--
      uint VSN=VolumeSerialNumber[0];
      //--
      if(VSN==0)
        {
         res="0";
         Print("Error: Receiving VSN may fail on Mac / Linux.");
        }
      else
        {
         res=StringFormat("%X",VSN);
         res=StringSubstr(res,0,4)+"-"+StringSubstr(res,4,8);
         //Print("VSN successfully received.");
        }
      //--
     }
//---
   return(res);
  }
  
//gravar o placar
/*void GravarContSinais(int cont_sinais){
      int handle;
      
      handle=FileOpen("cont_sinais.csv",FILE_CSV|FILE_READ|FILE_WRITE,';');
      
      if(handle<1){
         Comment("File placar.csv not found, the last error is ", GetLastError());
      }else{
         FileWrite(handle, IntegerToString(cont_sinais));
      }
      
      FileClose(handle);
}

//gravar os sinais
void GravarAtualizacaoSinais(int data_time, int op, string simbolo, int timeframe){
      int handle;
      handle=FileOpen("history_sinals.csv", FILE_CSV|FILE_WRITE|FILE_READ, ';');
      
      if(handle>0){
        FileSeek(handle, 0, SEEK_END);
        FileWrite(handle, data_time, op, simbolo, timeframe);
      }
      
      FileClose(handle);
}

void AtualizarContSinais(){
      string str = "";
      string sep = ";";
      ushort u_sep = StringGetCharacter(sep, 0);
      
      int fp = FileOpen("cont_sinais.csv", FILE_READ);
      if(fp!=INVALID_HANDLE && mode_backtest!=true){
            FileSeek(fp, 0, SEEK_SET);
            
            while(!FileIsEnding(fp)){
               str = FileReadString(fp, 0);
            }
         
         cont_sinais = StringToInteger(str);
      }
      
      FileClose(fp);
}

void AtualizarSinais(){
      //Reinicia contador

      string str = "";
      string sep = ";";
      ushort u_sep = StringGetCharacter(sep, 0);
      
      int fp = FileOpen("history_sinals.csv", FILE_READ);
      if(fp!=INVALID_HANDLE ){
            string sinais[];
            
            FileSeek(fp, 0, SEEK_SET);
            while(!FileIsEnding(fp)){
               str = FileReadString(fp, 0);
               ArrayResize(sinais,ArraySize(sinais)+1);
               sinais[ArraySize(sinais)-1] = str;
            }   
            
            int sinais_size = ArraySize(sinais);
            for(int i=0; i<sinais_size; i+4){
                  if(sinais[i+2] == Symbol() && StringToInteger(sinais[i+3]) == Period()){ 
                  
                     int index = iBarShift(NULL,0,StringToTime(sinais[i]));
                     int op = sinais[i+1];
                     
                     if(op == CALL) up[index] = NormalizeDouble(Low[index]-20*Point,Digits);
                     else down[index] = NormalizeDouble(High[index]+20*Point,Digits);
                     
                     if(i<sinais_size-1) realizar_backtest(op,index-1);
                     else{
                        operacao[0]=op;
                        operacao[1]=sinais[i];
                     }
                     
                  }
            }
      }
      
      FileClose(fp);
}*/

void GravarSerialKey(string serial_key){
      int handle;
      
      handle=FileOpen("serial_key.txt",FILE_TXT|FILE_READ|FILE_WRITE,';');
      
      if(handle<1){
         Comment("File serial_key.txt not found, the last error is ", GetLastError());
      }else{
         FileWrite(handle, serial_key);
      }
      
      FileClose(handle);
}

string GetSerialKey(){
      string str = "";
      string sep = ";";
      ushort u_sep = StringGetCharacter(sep, 0);
      
      int fp = FileOpen("serial_key.txt", FILE_READ);
      if(fp!=INVALID_HANDLE){
            FileSeek(fp, 0, SEEK_SET);
            str = FileReadString(fp, 0);
            FileClose(fp);
            return(str);
      }
      
      FileClose(fp);
      return("");
}