//+------------------------------------------------------------------+
//|                                               probabilistico.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Jam Sávio"
#property link      "mailto:jamsaavio@gmail.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 clrYellow
#property indicator_color2 clrYellow
#property indicator_color3 clrYellow
#property indicator_color4 clrYellow

input    bool     apenas_call    =     false;
input    bool     apenas_put     =     false;
input    int      qtd            =     3; 
input    int      total_bars     =     500;

double ganhou[], perdeu[], up[], down[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//--- indicator buffers mapping
   //--- indicator buffers mapping
   SetIndexStyle(0,DRAW_ARROW,NULL,1);
   SetIndexArrow(0,233); //221 for up arrow
   SetIndexBuffer(0,up);
   SetIndexLabel(0,"UP S3");
   
   SetIndexStyle(1,DRAW_ARROW,NULL,1);
   SetIndexArrow(1,234); //222 for down arrow
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
  
//---
   return(0);
  }

int deinit(){
   ObjectsDeleteAll();
   return(0);
}

int start(){
  int i=0, 
      count=0, 
      win=0, 
      loss=0, 
      draw=0, 
      maior_loss_consecutivo=0, 
      maior_win_consecutivo=0, 
      qtd_win_consecutivo=0, 
      qtd_loss_consecutivo=0;
   
   if(apenas_put == false){
      for(i=total_bars; i>qtd; i--){
         if(Close[i] > Open[i] && count<qtd) count++;
         
         else if(Close[i] <= Open[i] && count<qtd) count=0;
         
         else if(Close[i] > Open[i] && count==qtd){
           up[i] = Low[i];
           ganhou[i] = High[i];
           win++;
           qtd_win_consecutivo++;
           qtd_loss_consecutivo=0;
           count=0;
           if(qtd_win_consecutivo > maior_win_consecutivo) maior_win_consecutivo = qtd_win_consecutivo;
         }
         
         else if(Close[i] < Open[i] && count==qtd){
           up[i] = Low[i];
           perdeu[i] = High[i];
           loss++;
           qtd_loss_consecutivo++;
           qtd_win_consecutivo=0;
           count=0;
           if(qtd_loss_consecutivo > maior_loss_consecutivo) maior_loss_consecutivo = qtd_loss_consecutivo;
         }
         
         else if(Close[i] == Open[i] && count==qtd){
           up[i] = Low[i];
           draw++;
           count=0;
         }      
      }
   }
   
   if(apenas_call == false){
      for(i=total_bars; i>qtd; i--){
         if(Close[i] < Open[i] && count<qtd) count++;
         
         else if(Close[i] >= Open[i] && count<qtd) count=0;
         
         else if(Close[i] < Open[i] && count==qtd){
           down[i] = High[i];
           ganhou[i] = Low[i];
           win++;
           qtd_win_consecutivo++;
           qtd_loss_consecutivo=0;
           count=0;
           if(qtd_win_consecutivo > maior_win_consecutivo) maior_win_consecutivo = qtd_win_consecutivo;
         }
         
         else if(Close[i] > Open[i] && count==qtd){
           down[i] = High[i];
           perdeu[i] = Low[i];
           loss++;
           qtd_loss_consecutivo++;
           qtd_win_consecutivo=0;
           count=0;
           if(qtd_loss_consecutivo > maior_loss_consecutivo) maior_loss_consecutivo = qtd_loss_consecutivo;
         }
         
         else if(Close[i] == Open[i] && count==qtd){
           down[i] = High[i];
           draw++;
           count=0;
         }      
      }
   }
   
   int total = win+loss+draw;
   string operacao_tipo="";
   if(!apenas_call && !apenas_put) operacao_tipo = "Call & Put";
   else if(!apenas_call && apenas_put) operacao_tipo = "Put";
   else if(apenas_call && !apenas_put) operacao_tipo = "Call";
   
   
   //---------------Retângulo do painel
   ObjectCreate("MAIN",OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSet("MAIN",OBJPROP_CORNER,2);
   ObjectSet("MAIN",OBJPROP_XDISTANCE,10);
   ObjectSet("MAIN",OBJPROP_YDISTANCE,80);
   ObjectSet("MAIN",OBJPROP_XSIZE,400);
   ObjectSet("MAIN",OBJPROP_YSIZE,65);
   ObjectSet("MAIN",OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSet("MAIN",OBJPROP_COLOR,clrWhite);
   ObjectSet("MAIN",OBJPROP_BGCOLOR,clrMidnightBlue);

   //---------------Painel 1
   int font_size=8;
   string font_type="Time New Roman";
   
   string text = "   |               Bars Block: "+IntegerToString(qtd);
   CreateTextLable("bars_block",text,font_size,font_type,clrYellow,0,260,20,2);
   
   text = "   |               Total Bars: "+IntegerToString(total_bars);
   CreateTextLable("total_bars",text,font_size,font_type,clrYellow,0,260,40,2);
   
   text = "   |               Operar: "+operacao_tipo;
   CreateTextLable("operacao_tipo",text,font_size,font_type,clrYellow,0,260,60,2);
   
   //---------------Painel 2
   text = "Total Entradas: "+IntegerToString(total);
   CreateTextLable("totaL_entradas",text,font_size,font_type,clrYellow,0,20,60,2);
   
   double taxa_win = 100*win/total;
   text = "Win: "+IntegerToString(win)+"  /  Win: "+DoubleToString(taxa_win,2)+"%  |  Loss: "+IntegerToString(loss)+"  |  Draw: "+IntegerToString(draw);
   CreateTextLable("resultados",text,font_size,font_type,clrYellow,0,20,40,2);
   
   if(apenas_call==true || apenas_put==true){
      text = "Win Consecutivo: "+IntegerToString(maior_win_consecutivo)+"  |  Loss Consecutivo: "+IntegerToString(maior_loss_consecutivo);
      CreateTextLable("resultados_consecutivos",text,font_size,font_type,clrYellow,0,20,20,2);
   }
   
   return(0);
}

void CreateTextLable
(string TextLableName, string Text, int TextSize, string FontName, color TextColor, int TextCorner, int X, int Y, int Corner)
{
//---
   ObjectCreate(TextLableName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(TextLableName, OBJPROP_CORNER, Corner);
   ObjectSet(TextLableName, OBJPROP_XDISTANCE, X);
   ObjectSet(TextLableName, OBJPROP_YDISTANCE, Y);
   ObjectSetText(TextLableName,Text,TextSize,FontName,TextColor);
}
