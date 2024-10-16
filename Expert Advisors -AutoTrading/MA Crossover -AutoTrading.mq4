//+------------------------------------------------------------------+
//|                          2 MA Crossover EA                      |
//| Expert Advisor that opens orders at the crossover of two MAs     |
//| Version 1.00                                                     |
//+------------------------------------------------------------------+

#property strict
#property description   "This EA opens orders at the crossover of two moving average (MA) indicators"
#property description   "Test on a Demo Account first"


extern double TradeLotSize=0.1;             //Position size

extern bool UseNextEntryForExit=true;       //Use next entry to close the trade (if false uses take profit)
extern double TradeStopLoss=50;             //Stop loss in pips
extern double TradeTakeProfit=80;           //Take profit in pips

extern int AllowedSlippage=2;               //Slippage in pips

extern bool EnableTrading=true;             //Enable trading

extern int FastMAPeriod=50;                 //Fast moving average period
extern int SlowMAPeriod=100;                //Slow moving average period

//Functional variables
double NormalizedPoint;                     //Point normalized

bool AllowNewOrder;                         //Check for risk management
bool AllowBuyOrder;                         //Flag if there are buy orders open
bool AllowSellOrder;                        //Flag if there are sell orders open

int MaxOrderRetry=10;                       //Number of attempts to perform a trade operation
int RetrySleepSecs=3;                       //Seconds to sleep if can't order
int RequiredMinBars=60;                     //Minimum bars in the graph to enable trading

//Functional variables to determine prices
double MinimumSL;
double MaximumSL;
double CalculatedTP;
double CalculatedSL;
double CurrentSpread;
int SlippageAdjustment;


string labelName = "Test on Demo";
string labelText = "Test on Demo";
int labelFontSize = 18;
color labelColor = Yellow;
int spaceFromBottom = 50;

// Additional text for the updated version
string updatedLabelName = "updated_version_label";
string updatedLabelText = "Updated version available";
int updatedLabelFontSize = 12;  // Smaller font size for the updated version text
color updatedLabelColor = White;
int updatedSpaceFromBottom = 20;  // Position it below the main label

void createOrUpdateLabels()
{
    // Create the main label
    if (ObjectFind(0, labelName) == -1)
    {
        ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
        ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, spaceFromBottom);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, labelColor);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, labelFontSize);
        ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
    }

    // Create the updated version label below the main label
    if (ObjectFind(0, updatedLabelName) == -1)
    {
        ObjectCreate(0, updatedLabelName, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, updatedLabelName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
        ObjectSetInteger(0, updatedLabelName, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, updatedLabelName, OBJPROP_YDISTANCE, updatedSpaceFromBottom);
        ObjectSetInteger(0, updatedLabelName, OBJPROP_COLOR, updatedLabelColor);
        ObjectSetInteger(0, updatedLabelName, OBJPROP_FONTSIZE, updatedLabelFontSize);
        ObjectSetString(0, updatedLabelName, OBJPROP_TEXT, updatedLabelText);
    }
}


//Variable initialization function
void InitializeTrade(){          
   RefreshRates();
   NormalizedPoint=Point;
   SlippageAdjustment=AllowedSlippage;
   if (MathMod(Digits,2)==1){
      NormalizedPoint*=10;
      SlippageAdjustment*=10;
   }
   CalculatedTP=TradeTakeProfit*NormalizedPoint;
   CalculatedSL=TradeStopLoss*NormalizedPoint;
   AllowNewOrder=EnableTrading;
   AllowBuyOrder=true;
   AllowSellOrder=true;
}


//Check if orders can be submitted
void CheckTradeEligibility(){            
   if( Bars<RequiredMinBars ){
      Print("INFO - Not enough Bars to trade");
      AllowNewOrder=false;
   }
   CheckOpenOrders();
   return;
}


//Check if there are open orders and what type
void CheckOpenOrders(){
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == false ) {
         Print("ERROR - Unable to select the order - ",GetLastError());
         break;
      }
      if( OrderSymbol()==Symbol() && OrderType() == OP_BUY) AllowBuyOrder=false;
      if( OrderSymbol()==Symbol() && OrderType() == OP_SELL) AllowSellOrder=false;
   }
   return;
}


//Close all the orders of a specific type and current symbol
void CloseAllOrders(int OrderType){
    double ClosePrice=0;
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == false ) {
         Print("ERROR - Unable to select the order - ",GetLastError());
         break;
      }
      if( OrderSymbol()==Symbol() && OrderType()==OrderType) {
         if(OrderType==OP_BUY) ClosePrice=Bid;
         if(OrderType==OP_SELL) ClosePrice=Ask;
         double Lots=OrderLots();
         int Ticket=OrderTicket();
         for(int j=1; j<MaxOrderRetry; j++){
            bool res=OrderClose(Ticket,Lots,ClosePrice,10,Red);
            if(res){
               Print("TRADE - CLOSE - Order ",Ticket," closed at price ",ClosePrice);
               break;
            }
            else Print("ERROR - CLOSE - error closing order ",Ticket," return error: ",GetLastError());
         }
      }
   }
   return;
}


//Open new order of a given type
void OpenNewOrder(int OrderType){
    RefreshRates();
    double OpenOrderPrice = 0;
    double StopLossPrice = 0;
    double TakeProfitPrice = 0;
    string volumeCheckDescription = "";

    // Check if the volume is valid
    if (!CheckVolumeValue(TradeLotSize, volumeCheckDescription)) {
        Print("ERROR - Invalid volume: ", volumeCheckDescription);
        return;
    }

    if (OrderType == OP_BUY) {
        OpenOrderPrice = Ask;
        if (!UseNextEntryForExit) {
            StopLossPrice = OpenOrderPrice - CalculatedSL;
            TakeProfitPrice = OpenOrderPrice + CalculatedTP;
        }
    }

    if (OrderType == OP_SELL) {
        OpenOrderPrice = Bid;
        if (!UseNextEntryForExit) {
            StopLossPrice = OpenOrderPrice + CalculatedSL;
            TakeProfitPrice = OpenOrderPrice - CalculatedTP;
        }
    }

    for (int i = 1; i < MaxOrderRetry; i++) {
        int res = OrderSend(Symbol(), OrderType, TradeLotSize, OpenOrderPrice, SlippageAdjustment,
                            NormalizeDouble(StopLossPrice, Digits), NormalizeDouble(TakeProfitPrice, Digits), "", 0, 0, Green);
        if (res > 0) {
            Print("TRADE - NEW - Order ", res, " submitted: Command ", OrderType, " Volume ", TradeLotSize, " Open ", OpenOrderPrice,
                  " Slippage ", SlippageAdjustment, " Stop ", StopLossPrice, " Take ", TakeProfitPrice);
            break;
        } else {
            Print("ERROR - NEW - error sending order, return error: ", GetLastError());
        }
    }
}


// Function to check the validity of the order volume
bool CheckVolumeValue(double volume, string &description) {
    double min_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double volume_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

    if (volume < min_volume) {
        description = StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f", min_volume);
        return false;
    }

    if (volume > max_volume) {
        description = StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f", max_volume);
        return false;
    }

    int ratio = (int)MathRound(volume / volume_step);
    if (MathAbs(ratio * volume_step - volume) > 0.0000001) {
        description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                   volume_step, ratio * volume_step);
        return false;
    }

    description = "Correct volume value";
    return true;
}

//Technical analysis of the indicators
bool FastMACrossToBuy=false;
bool FastMACrossToSell=false;

void AnalyzeMACross(){
   FastMACrossToBuy=false;
   FastMACrossToSell=false;
   double SlowMACurrent=iMA(Symbol(),0,SlowMAPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   double SlowMAPrevious=iMA(Symbol(),0,SlowMAPeriod,0,MODE_EMA,PRICE_CLOSE,2);
   double FastMACurrent=iMA(Symbol(),0,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   double FastMAPrevious=iMA(Symbol(),0,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,2);
   if(SlowMAPrevious>FastMAPrevious && FastMACurrent>SlowMACurrent){
      FastMACrossToBuy=true;
   }
   if(SlowMAPrevious<FastMAPrevious && FastMACurrent<SlowMACurrent){
      FastMACrossToSell=true;
   }
}




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
createOrUpdateLabels();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Calling initialization, checks and technical analysis
   InitializeTrade();
   CheckTradeEligibility();
   AnalyzeMACross();
   //Check of Entry/Exit signal with operations to perform
   if(FastMACrossToBuy){
      if(UseNextEntryForExit) CloseAllOrders(OP_SELL);
      if(AllowBuyOrder && AllowSellOrder && AllowNewOrder) OpenNewOrder(OP_BUY);
   }
   if(FastMACrossToSell){
      if(UseNextEntryForExit) CloseAllOrders(OP_BUY);
      if(AllowSellOrder && AllowBuyOrder && AllowNewOrder) OpenNewOrder(OP_SELL);
   }
  }
//+------------------------------------------------------------------+