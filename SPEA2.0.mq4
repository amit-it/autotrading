//+------------------------------------------------------------------+
//|                                                      SPEA1.0.mq4 |
//|                                                             amit |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "amit"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#define MAGICMA  0

extern bool      useProfitToClose       = true;
extern bool      useStopLoss            = false;
extern double    profitToClose          = 0.25;
extern bool      useLossToClose         = false;
extern double    lossToClose            = 50;
extern bool      AllSymbols             = false;
extern bool      PendingOrders          = true;
extern double    MaxSlippage            = 3;
extern string    FileName = "Trades-Strat2-2018-10-29.CSV";
extern int paircolindex = 0;
extern int datecolindex = 1;
extern bool MM = TRUE;
extern double FixedSL = 5;
extern double AccountBalanceRiskPerc = 0.01;
extern double LotDigits =2;
extern int TradingStartHour = 00;
extern int TradingStartMin = 10;
extern int TradingEndHour = 22;
extern int TradingEndMin = 00;
extern double MinOverallProfitPercent = 3.0;
extern string Inditext = "Exit Percentage:";
extern int Size = 14;
string FontType = "Verdana";
extern color Color = Blue;
extern int Corner = 0;
extern int yLine = 20;
extern int xCol = 10;
extern int window = 0;
extern double StartingAccountBalance;

string mp[8][10000]; // variable to store model results in array
int rows,rowsBuyOrCell ;

double pips2dbl, pips2point, pipValue, maxSlippage, profit;
bool   clear;

//+------------------------------------------------------------------+
//| expert initialization function
//| load model results into an array variable before trade start                                 |
//+------------------------------------------------------------------+

int OnInit(){
    int row=0,col=0,rowsBuyOrCell=0;;
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
           rowsBuyOrCell++;
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

double OverAllProfitCheck() {
    double AccountEquityBalance = AccountEquity();
    
    double profit=0;
    
    double total_invested = 0;
    int total  = OrdersTotal();
    for (int cnt = total-1 ; cnt >=0 ; cnt--)
    {   
        if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
        {
        profit += OrderProfit();
        total_invested += OrderOpenPrice() * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE)/MarketInfo(OrderSymbol(), MODE_TICKSIZE);
        }
    }
    
    datetime today_midnight=TimeCurrent()-(TimeCurrent()%(PERIOD_D1*60));    
    for(int i=OrdersHistoryTotal()-1;i>=0;i--){
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)&& OrderOpenTime()>=today_midnight)
        {
        profit += OrderProfit();
        total_invested += OrderOpenPrice() * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE)/MarketInfo(OrderSymbol(), MODE_TICKSIZE);            
        }
    }
    if(total_invested==0) {
    return 0;
    }    
    else {
      //Print(profit+" ProfitOverall:"+(profit/StartingAccountBalance*100)+"Total Invested"+total_invested+" AccountEquityBalance"+AccountEquityBalance+" freemargin"+AccountFreeMargin()+"margin"+AccountMargin());
      return(profit/StartingAccountBalance*100);
    }
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
    double lots;
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double leverage = AccountLeverage();
    double lotsize = MarketInfo(Symbol(), MODE_LOTSIZE);
    double stoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    double pricePerLot = MarketInfo(Symbol(),MODE_MARGINREQUIRED);

    if(MM)
    {
        lots = NormalizeDouble(StartingAccountBalance * AccountBalanceRiskPerc * Risk/100 / pricePerLot, LotDigits);
        //Print("New Lot Size"+lots+" MaxLotsAllowed"+maxlot);
        if(lots < minlot) lots = minlot;

        if (AccountFreeMargin() < Ask * lots * lotsize / leverage) {
            //Print("We have no money. Lots = ", lots, " , Free Margin = ", AccountFreeMargin());
        }
    }
    else lots=NormalizeDouble(minlot,Digits);
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
            mpv[5] = mp[6][i];
            mpv[6] = mp[7][i];
            mpv[7] = 1;
        }
    }   
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

int TotalClosedOrderInHistory() {
    int count = 0;
    datetime today_midnight=TimeCurrent()-(TimeCurrent()%(PERIOD_D1*60));    
    for(int i=OrdersHistoryTotal()-1;i>=0;i--){
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)&& OrderOpenTime()>=today_midnight)
        {
            count++;
        }
    }
    return count;
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
    ArrayInitialize(modelPredictedDetails,0);
    double oLots,minstoplevel,stoploss,takeprofit,nolots;
    int    ticket,total,totalOrderInHistory;
    datetime today_midnight=TimeCurrent()-(TimeCurrent()%(PERIOD_D1*60));
    double TodayOpenPrice = iOpen(Symbol(), PERIOD_M1, iBarShift(Symbol(), PERIOD_M1, today_midnight));
    Print("TodayOpenPrice:"+TodayOpenPrice); 
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
    double wtg = 100/14;  //modelPredictedDetails[2]
    oLots = GetLots(wtg);

    total=OrdersTotal();
    totalOrderInHistory = TotalClosedOrderInHistory();
    Print("Flag:"+modelPredictedDetails[7]+" 2:"+modelPredictedDetails[2]+" 3:"+modelPredictedDetails[3]+" 4:"+modelPredictedDetails[4]+" 5:"+modelPredictedDetails[5]+" 6:"+modelPredictedDetails[6]);
    int TotalOpenedClosedOrders = total + totalOrderInHistory;  
    
    if(modelPredictedDetails[7]==0){
            Print("Model Predictition NA for this.");
            return;
        }  
    if(Opened() == 0 && !IsTradeExistInHistory())
    {  
        Print("Opened Order for "+Symbol()+":"+Opened()+" is available in history " + IsTradeExistInHistory());   
        //--- no opened orders identified
        if(AccountFreeMargin()<(16*oLots))
        {
            Print("We have no money. Free Margin = ",AccountFreeMargin());
            return;
        }      
        
        
        RefreshRates();
        // Check Buy condition for current symbol  
        double MinPrice = TodayOpenPrice * (100+modelPredictedDetails[6])/100;
        Print("Ask:"+Ask+" Min"+MinPrice+" Buy Condition:"+(Ask<=MinPrice));
        //Print("date:"+modelPredictedDetails[1]+" 2:"+modelPredictedDetails[2]+" 3:"+modelPredictedDetails[3]+" 4:"+modelPredictedDetails[4]+" 5:"+modelPredictedDetails[5]+" 6:"+modelPredictedDetails[6]);
        //return ;
        if(Ask <= MinPrice) {
        stoploss = NormalizeDouble(Bid*(100-FixedSL)/100,Digits); 
        double minstoploss = NormalizeDouble(Bid - minstoplevel*Point,Digits);
        takeprofit = NormalizeDouble(TodayOpenPrice*(100+modelPredictedDetails[5])/100,Digits);
        Print("Buy Ask:"+Ask+",minSL:"+minstoploss+", SL:"+stoploss+",& TP:"+takeprofit);
        if (stoploss > minstoploss) {stoploss = minstoploss; }         
        ticket=OrderSend(Symbol(),OP_BUY,oLots,Ask,3,stoploss, takeprofit,"",MAGICMA,0,Blue);
        if(ticket>0) {}
        else
            Print("Error opening BUY order : ",GetLastError());
        
        }
        // Check Sell condition for current symbol  
        double MaxPrice = TodayOpenPrice * (100+modelPredictedDetails[5])/100;
        Print("Bid:"+Bid+" Max"+MaxPrice+", Sell Condition:"+(Bid>=MaxPrice));
        
        if(Bid >= MaxPrice) {
        stoploss = NormalizeDouble(Ask*(100+FixedSL)/100,Digits); 
        double minstoploss = NormalizeDouble(Ask+minstoplevel*Point,Digits);
        takeprofit = NormalizeDouble(TodayOpenPrice*(100-modelPredictedDetails[6])/100,Digits);   
        Print("Sell Ask:"+Ask+",minSL:"+minstoploss+", SL:"+stoploss+",& TP:"+takeprofit);
        if (stoploss < minstoploss) {stoploss = minstoploss; }         
        ticket=OrderSend(Symbol(),OP_SELL,oLots,Bid,3,stoploss,takeprofit,"",MAGICMA,0,Red);
        if(ticket>0){}
        else
           Print("Error opening SELL order : ",GetLastError());        
        }        
       
    }

       
     // Close all open order at end of day;
    Print("OverAllProfitPercent: "+OverAllProfitCheck());
    Print("Hour:"+Hour()+", "+TradingEndHour+" Minute:"+Minute()+" TradingEndMin:"+TradingEndMin+" Orders:"+OrdersTotal());    
    //double overallprofit_latest = (AccountEquity() - StartingAccountBalance)/ StartingAccountBalance * 100;
    //Print("LAtest Overall Profit:"+overallprofit_latest+" StartAccBal"+StartingAccountBalance+" Profit"+(AccountEquity() - StartingAccountBalance) );
    if ((Hour() == TradingEndHour && Minute() >= TradingEndMin && OrdersTotal() > 0)|| MinOverallProfitPercent <= OverAllProfitCheck()){
            Print("Closing All Orders Now.");
            CloseDeleteAll();
        }

}

//+------------------------------------------------------------------+