//+------------------------------------------------------------------+
//|                                                MPEA1.0.mq4 |
//|                                                       amit |
//+------------------------------------------------------------------+
#property copyright "amit"
#property link      ""
#property version   "1.00"
#property strict
#define MAGICMA  0

//Initializing variables
extern bool      useProfitToClose       = true;
extern double    profitToClose          = 0.25;
extern bool      useLossToClose         = false;
extern double    lossToClose            = 50;
extern bool      AllSymbols             = false;
extern bool      PendingOrders          = true;
extern double    MaxSlippage            = 3;
input double     Lots          =0.1;
extern string    FileName = "Trades-2018-07-12.CSV";
extern int paircolindex = 0;
extern int datecolindex = 1;
extern bool MM = TRUE;
extern double Risk = 2;
extern double LotDigits =2;
extern int TradingStartHour = 00;
extern int TradingStartMin = 10;
extern int TradingEndHour = 22;
extern int TradingEndMin = 00;
extern int MinOverallProfitPercent = 3; 

extern string Inditext = "Exit Percentage:";
extern int Size = 14;
string FontType = "Verdana";
extern color Color = Blue;
extern int Corner = 0;
extern int yLine = 20;
extern int xCol = 10;
extern int window = 0;
extern double StartingAccountBalance; 

string mp[6][10000]; // variable to store model results in array
int rows ;

double pips2dbl, pips2point, pipValue, maxSlippage, profit;
bool   clear;

//+------------------------------------------------------------------+
//| expert initialization function
//| load model results into an array variable before trade start                                 |
//+------------------------------------------------------------------+

int OnInit(){
    int row=0,col=0;
    int colCnt;
    StartingAccountBalance = AccountBalance();
    int handle=FileOpen(FileName,FILE_CSV|FILE_READ,",");

    if(handle>0)
    {
        while(True)
        {
            if(FileIsEnding(handle)) break;
            string temp = FileReadString(handle);

            mp[col][row]=temp;
            if(FileIsLineEnding(handle))
            {
                colCnt = col;
                col = 0;
                row++;
            }
            else
            {
                col++;
            }
            rows = row-1;
        }
        FileClose(handle);
    }
    else
    {
        Print("File "+FileName+" not found, the last error is ", GetLastError());
        return(false);
    }

    // Adjust for five (5) digit brokers.
    if (Digits == 5 || Digits == 3)
    {
        pips2dbl = Point*10; pips2point = 10;pipValue = (MarketInfo(Symbol(),MODE_TICKVALUE))*10;
    }
    else
    {
        pips2dbl = Point;   pips2point = 1;pipValue = (MarketInfo(Symbol(),MODE_TICKVALUE))*1;
    }
    // Open Chart window for currency pairs listed in model results
    
   
    for(int i = 1; i <= rows ; i++){   
        string sy = mp[0][i];
        StringToUpper(sy);        
        long chartId= CheckChartWindowOpen(sy);
        if(chartId>0){
        ChartRedraw(chartId);
        Sleep(1000);
        }
        else {
        ChartOpen(sy,PERIOD_D1);
        Sleep(1000);
        }               
    }
    
    clear = true;
    return(0);
}
// Check whether chart window already open
long CheckChartWindowOpen(string pair){
   string chart_symbol;
   long chartID=ChartFirst();
   while(chartID >= 0)
   {
   chart_symbol = ChartSymbol(chartID); 
   if(chart_symbol==pair){
   return chartID;
   }
   chartID = ChartNext(chartID);   
   }
   return 0;
}
// function to close all open orders
bool CloseDeleteAll() {
    int total  = OrdersTotal();
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {
        OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);

        if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
        {
            switch(OrderType())
            {
                case OP_BUY       :
                {
                    if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),maxSlippage,Violet))
                        return(false);
                }break;
                case OP_SELL      :
                {
                    if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),maxSlippage,Violet))
                        return(false);
                }break;
            }


            if(OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP || OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT)
                if(!OrderDelete(OrderTicket()))
                {
                    Print("Error deleting " + OrderType() + " order : ",GetLastError());
                    return (false);
                }
        }
    }
    return (true);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
// delete all on current chart
bool CloseDeleteAllCurrent() {
    int total  = OrdersTotal();
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {
        OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);

        if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
        {
            if(OrderSymbol()==Symbol())
            {
                switch(OrderType())
                {
                    case OP_BUY       :
                    {
                        if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),maxSlippage,Violet))
                            return(false);
                    }break;

                    case OP_SELL      :
                    {
                        if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),maxSlippage,Violet))
                            return(false);
                    }break;
                }


                if(OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP || OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT)
                    if(!OrderDelete(OrderTicket()))
                    {
                        return (false);
                    }
            }
        }
    }
    return (true);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
// left pending orders
bool CloseDeleteAllNonPending() {
    int total  = OrdersTotal();
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {
        OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);

        if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
        {
            switch(OrderType())
            {
                case OP_BUY       :
                {
                    if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),maxSlippage,Violet))
                        return(false);
                }break;
                case OP_SELL      :
                {
                    if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),maxSlippage,Violet))
                        return(false);
                }break;
            }
        }
    }
    return (true);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
// delete all on current chart left pending
bool CloseDeleteAllCurrentNonPending() {
    int total  = OrdersTotal();
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {
        OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);

        if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
        {
            if(OrderSymbol()==Symbol())
            {
                switch(OrderType())
                {
                    case OP_BUY       :
                    {
                        if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),maxSlippage,Violet))
                            return(false);
                    }break;

                    case OP_SELL      :
                    {
                        if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),maxSlippage,Violet))
                            return(false);
                    }break;
                }
            }
        }
    }
    return (true);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Profit Check
double ProfitCheck() {
    double profit=0;
    int total  = OrdersTotal();
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {
        OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
        if(AllSymbols)
            profit+=OrderProfit();
        else if(OrderSymbol()==Symbol())
            profit+=OrderProfit();
    }
    return(profit);
}

double getInvestment(int what)
{
   double projected = 0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
            double pip = MathAbs(OrderOpenPrice()-OrderStopLoss());
            double pipC = MathAbs(OrderOpenPrice()-OrderClosePrice());
            double delta = MarketInfo (OrderSymbol (), MODE_TICKVALUE) / MarketInfo(OrderSymbol(), MODE_TICKSIZE);
            double p = pip*delta*OrderLots();
            double pC = pipC*delta*OrderLots();
            if(pC == 0) pC = 1.0;
            double exchange = OrderProfit()/pC;
            p *= exchange;
            p += OrderCommission();
            p += OrderSwap();
            if(what == 0 && OrderProfit() > 0){
               projected += p;
               }
            else if(what == 1 && (( (OrderType() == OP_SELL && OrderStopLoss() > OrderOpenPrice()) ||
                                (OrderType() == OP_BUY && OrderStopLoss() < OrderOpenPrice()) )
                                ||
                                OrderStopLoss() == 0)
                     )
            projected += p;
      }
   }
   return (projected);
}
double OverAllProfitCheck() {
    double AccountEquityBalance = AccountEquity();
    
    double profit=AccountEquityBalance - StartingAccountBalance;
    
    double total_invested = 0;
    int total  = OrdersTotal();
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {   Print("Open Order Amount"+(OrderOpenPrice() * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE)/MarketInfo(OrderSymbol(), MODE_TICKSIZE)));
           
        Print("Profit2"+OrderProfit()+"Profit1"+((OrderOpenPrice()-OrderClosePrice()) * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE)/MarketInfo(OrderSymbol(), MODE_TICKSIZE)));        
        OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
        profit+=OrderProfit();
        total_invested +=OrderOpenPrice();
    }
    return(profit/total_invested*100);
}

//Check opened price for a pair
double PriceWhenOrderOpendForCurrentPair() {
    double existing = 0;
    if(Opened() == 1){
        int total  = OrdersTotal();
        for (int cnt = total-1 ; cnt >=0 ; cnt--)
        {
            OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
            //Print("OpenPrice"+OrderOpenPrice());
            if(OrderSymbol()==Symbol())
                existing = OrderOpenPrice();
        }
    }
    return(existing);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check number of opened order for current Symbol
int Opened() {
    int total  = OrdersTotal();
    int count = 0;
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {
        OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
        if(AllSymbols)
        {
            if(PendingOrders)
                count++;
            if(!PendingOrders)
                if(OrderType()==OP_BUY || OrderType()==OP_SELL)
                    count++;
        }
        if(!AllSymbols)
        {
            if(OrderSymbol()==Symbol())
            {
                if(PendingOrders)
                    count++;
                if(!PendingOrders)
                    if(OrderType()==OP_BUY || OrderType()==OP_SELL)
                        count++;
            }
        }
    }
    return (count);
}

double GetLots(double Risk) {
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double leverage = AccountLeverage();
    double lotsize = MarketInfo(Symbol(), MODE_LOTSIZE);
    double stoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    double lots = Lots;
    double MinLots = 0.01; double MaximalLots = 50.0;

    if(MM)
    {
        lots = NormalizeDouble(AccountFreeMargin() * Risk/100 / 1000.0, LotDigits);
        if(lots < minlot) lots = minlot;
        if (lots > MaximalLots) lots = MaximalLots;
        if (AccountFreeMargin() < Ask * lots * lotsize / leverage) {
            //Print("We have no money. Lots = ", lots, " , Free Margin = ", AccountFreeMargin());
        }}
    else lots=NormalizeDouble(Lots,Digits);
    return(lots);
}

//|----------------------------------------------------+
//|funtion to get the model predicted values from model
//|results for specific symbol/curreny pair
//|----------------------------------------------------+
void getModelPredictedValue( double& mpv[],datetime current_time,string pair){
    //string ct=StringSubstr(TimeToStr(current_time,TIME_DATE|TIME_SECONDS),0,13);
    string ct = TimeToStr(current_time,TIME_DATE);
    //Print("CTime"+ct+" pair"+pair);
    StringReplace(ct,".","");
    StringToLower(pair);

    for(int i = 1; i <= rows ; i++){
        //Print("Row"+mp[datecolindex][i]);
        if(mp[datecolindex][i]==ct && mp[paircolindex][i]==pair){
            mpv[1] = mp[2][i];
            mpv[2] = mp[3][i];
            mpv[3] = mp[4][i];
            mpv[4] = mp[5][i];
        }
    }
    //Print("MV"+mpv[2]);
    return;
}

bool IsTradeExistInHistory() {
    bool isExistInHistory = false;
    datetime today_midnight=TimeCurrent()-(TimeCurrent()%(PERIOD_D1*60));    
    for(int i=OrdersHistoryTotal()-1;i>=0;i--){
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)&& OrderOpenTime()>=today_midnight)
        {
            if(OrderSymbol()==Symbol())
            {
                isExistInHistory = true;
            }
        }
    }
    return isExistInHistory;
}

bool CheckTradingTime()
{  
   if(Hour() > TradingStartHour || (Hour() == TradingStartHour && Minute() >= TradingStartMin)) return(false);  
   return(true);
}

//+------------------------------------------------------------------+
//| OnTick function to get new tick details for symbols                                                 |
//+------------------------------------------------------------------+
void OnTick() {
    double modelPredictedDetails[10];
    double oLots,minstoplevel,stoploss,takeprofit,nolots;
    int    ticket,total;
    //IsTradeExistInHistory();
    // Check where is autotrading enabled or not
    if(IsTradeAllowed()==false)
    {
        Print("Trade is not allowed");
        return;
    }
    if(CheckTradingTime()){
    Print("Trade is not allowed at this time.");
        return;
    }

    getModelPredictedValue(modelPredictedDetails,TimeCurrent(),Symbol());

    minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);

    oLots = GetLots(modelPredictedDetails[2]);

    total=OrdersTotal();
    Print("Total Opened"+total);
    Print("Opened Order for "+Symbol()+":"+Opened());
    //Print("Opened Order for "+Symbol()+":"+(Opened() == 0)+" is available in history " + IsTradeExistInHistory()); 
    if(Opened() == 0 && !IsTradeExistInHistory())
    {  
        Print("Opened Order for "+Symbol()+":"+Opened()+" is available in history " + IsTradeExistInHistory());   
        //--- no opened orders identified
        if(AccountFreeMargin()<(16*oLots))
        {
            Print("We have no money. Free Margin = ",AccountFreeMargin());
            return;
        }
        if(modelPredictedDetails[1]==0){
            Print("Model Predictition NA for this.");
            return;
        }
        RefreshRates();

        stoploss = modelPredictedDetails[4];//NormalizeDouble(Bid-minstoplevel*Point,Digits);
        takeprofit = 0;//NormalizeDouble(Bid+minstoplevel*Point,Digits);
        // Check Buy condition for current symbol
        
        if(modelPredictedDetails[1]==1){
            ticket=OrderSend(Symbol(),OP_BUY,oLots,Ask,3,stoploss, takeprofit,"",MAGICMA,0,Blue);
            if(ticket>0) {}
            else
                Print("Error opening BUY order : ",GetLastError());
        }
        if(modelPredictedDetails[1]==-1)
        {        
         ticket=OrderSend(Symbol(),OP_SELL,oLots,Bid,3,stoploss,takeprofit,"",MAGICMA,0,Red);
         if(ticket>0){}
         else
            Print("Error opening SELL order : ",GetLastError());
        }
        
    }

    if(!clear)
    {
        if(AllSymbols)
        {
            if(PendingOrders)
                if(CloseDeleteAll())
                    clear=true;
                else
                    return;
            if(!PendingOrders)
                if(CloseDeleteAllNonPending())
                    clear=true;
                else
                    return;
        }
        if(!AllSymbols)
        {
            if(PendingOrders)
                if(CloseDeleteAllCurrent())
                    clear=true;
                else
                    return;
            if(!PendingOrders)
                if(CloseDeleteAllCurrentNonPending())
                    clear=true;
                else
                    return;
        }
    }

    profit = ProfitCheck();
/*
    if(useProfitToClose)
    {
        if(profit>profitToClose)
        {
            Print("Closing Few Trade with profit");
            if(AllSymbols)
            {
                if(PendingOrders)
                    if(!CloseDeleteAll())
                        clear=false;
                if(!PendingOrders)
                    if(!CloseDeleteAllNonPending())
                        clear=false;
            }
            if(!AllSymbols)
            {
                if(PendingOrders)
                    if(!CloseDeleteAllCurrent())
                        clear=false;
                if(!PendingOrders)
                    if(!CloseDeleteAllCurrentNonPending())
                        clear=false;
            }
        }
    }
    if(useLossToClose)
    {
        if(profit<-lossToClose)
        {
            Alert("Closing Few Trade with profit");
            if(AllSymbols)
            {
                if(PendingOrders)
                    if(!CloseDeleteAll())
                        clear=false;
                if(!PendingOrders)
                    if(!CloseDeleteAllNonPending())
                        clear=false;
            }
            if(!AllSymbols)
            {
                if(PendingOrders)
                    if(!CloseDeleteAllCurrent())
                        clear=false;
                if(!PendingOrders)
                    if(!CloseDeleteAllCurrentNonPending())
                        clear=false;
            }
        }
    } */
    // Closed the order for currency if exit value more than the model exist value
    if(PriceWhenOrderOpendForCurrentPair()!=0) {    
        //ObjectDelete("ModelExitPerc"+Symbol());
        //DisplayText("ModelExitPerc"+Symbol(), yLine, xCol, "Thresold  "+DoubleToString(modelPredictedDetails[3],5) , Size,FontType, Red);
            
        if(modelPredictedDetails[1]==1) {
        double buyExistPercentValue = (MarketInfo(Symbol(), MODE_BID) - PriceWhenOrderOpendForCurrentPair()) / PriceWhenOrderOpendForCurrentPair()*100;
        //ObjectDelete("ExitPercPair"+Symbol());
        //DisplayText("ExitPercPair"+Symbol(), yLine+30, xCol, Inditext+"  "+ DoubleToString(buyExistPercentValue,5), Size,FontType, Color);
        
        if(buyExistPercentValue >  modelPredictedDetails[3]) {      
             if(AllSymbols)
               {
                  if(PendingOrders)
                     if(!CloseDeleteAll())
                        clear=false;
                  if(!PendingOrders)
                     if(!CloseDeleteAllNonPending())
                        clear=false;
               }
               if(!AllSymbols)
               {
                  if(PendingOrders)
                     if(!CloseDeleteAllCurrent())
                        clear=false;
                  if(!PendingOrders)
                     if(!CloseDeleteAllCurrentNonPending())
                        clear=false;
               }
        }
        }
        if(modelPredictedDetails[1]==-1){
        double sellExistPercentValue = (MarketInfo(Symbol(), MODE_ASK) - PriceWhenOrderOpendForCurrentPair()) / PriceWhenOrderOpendForCurrentPair()*100;      
        //Print("Sell ExitV"+sellExistPercentValue+" ModelExitV"+modelPredictedDetails[3]);
        //ObjectDelete("ExitPercPair"+Symbol());
        //DisplayText("ExitPercPair"+Symbol(), yLine+30, xCol, Inditext+"  "+ DoubleToString(sellExistPercentValue,5), Size,FontType, Color);  
        if(sellExistPercentValue <  modelPredictedDetails[3]) {      
             if(AllSymbols)
               {
                  if(PendingOrders)
                     if(!CloseDeleteAll())
                        clear=false;
                  if(!PendingOrders)
                     if(!CloseDeleteAllNonPending())
                        clear=false;
               }
               if(!AllSymbols)
               {
                  if(PendingOrders)
                     if(!CloseDeleteAllCurrent())
                        clear=false;
                  if(!PendingOrders)
                     if(!CloseDeleteAllCurrentNonPending())
                        clear=false;
               }
        }
        }        
                      
        
    }
     // Close all open order at end of day;
    Print("Get Invested"+getInvestment(1) + " in"+getInvestment(0)+ " Account Profit"+AccountProfit());
    if ((Hour() == TradingEndHour && Minute() >= TradingEndMin && OrdersTotal() > 0)|| MinOverallProfitPercent <= OverAllProfitCheck() ){
            Print("Closing All Orders Now.");
            CloseDeleteAll();
        }

}

void DisplayText(string eName, int eYD, int eXD, string eText, int eSize, string eFont, color eColor) {
   ObjectCreate(eName, OBJ_LABEL, window, 0, 0);
   ObjectSet(eName, OBJPROP_CORNER, Corner);
   ObjectSet(eName, OBJPROP_XDISTANCE, eXD);
   ObjectSet(eName, OBJPROP_YDISTANCE, eYD);
   ObjectSetText(eName, eText, eSize, eFont, eColor);
}

//+------------------------------------------------------------------+
