# Multiple Technical indicators to generate Trade Signals

This Expert Advisor (EA) implements multiple technical indicators to generate trade signals, provides configurable lot sizing, and manages trades based on specific conditions. By default, the EA is optimized for trading the EURUSD pair on a 5-minute chart, with settings based on historical optimizations since 2020.

## Features
- **Multiple Technical Indicators**: Utilizes moving averages (MA), relative strength index (RSI), MACD, Bollinger Bands, and Stochastic Oscillator for generating buy/sell signals.
- **Configurable Lot Sizing**: Supports fixed lot sizes, balance-based sizing, and equity-based sizing for flexible risk management.
- **Dynamic Trade Management**: Places trades based on signal confirmations and manages stop loss (SL) and take profit (TP) dynamically.
- **Error Handling**: Ensures smooth trade execution with error checking for order placements.

## Default Settings
The default settings of the EA are optimized for:
- **Symbol**: EURUSD
- **Timeframe**: 5-minute chart
- **Optimization Period**: Since 2020

## Input Parameters

### Trade Size Calculation
The EA supports three types of trade size calculations:
- **Fixed Lot Size**: Uses a predetermined lot size for every trade.
- **Balance Percentage**: Lot size is calculated as a percentage of the account balance.
- **Equity Percentage**: Lot size is calculated as a percentage of the account equity.

#### Trade Size Inputs:
- `FixedLotSize`: Set a fixed lot size for trades.
- `TradeSizePercent`: Define the percentage of balance/equity used for lot sizing.
- `TradeSizeType`: Choose between fixed, balance, or equity-based lot sizing.
- `MagicNumber`: A unique identifier for trades placed by this EA.

### Indicator Settings
The EA incorporates a variety of indicators, which can be toggled on or off to suit your strategy.

#### Available Indicators:
- **Moving Average (MA)**:
  - Configurable periods for short-term and long-term MAs.
  - Input: `UseMA`, `MAPeriod`.
  
- **Relative Strength Index (RSI)**:
  - Adjustable overbought/oversold levels.
  - Input: `UseRSI`, `RSI_Period`, `RSI_Overbought`, `RSI_Oversold`.
  
- **MACD**:
  - Adjustable fast and slow EMA periods, and signal line.
  - Input: `UseMACD`, `MACD_FastEMA`, `MACD_SlowEMA`, `MACD_SignalPeriod`.
  
- **Bollinger Bands**:
  - Configurable period and deviation settings.
  - Input: `UseBollinger`, `BB_Period`, `BB_Deviation`.
  
- **Stochastic Oscillator**:
  - Adjustable %K, %D, and slowing parameters.
  - Input: `UseStochastic`, `Stoch_K`, `Stoch_D`, `Stoch_Slowing`.

### Signal Detection

#### Buy Signal Conditions (`IsBuySignal()`):
The EA generates a buy signal when all selected conditions are met. Example buy conditions:
- **MA Condition**: Short-term MA is above the long-term MA.
- **RSI Condition**: RSI is below 50 (a more relaxed condition than oversold at 30).
- **MACD Condition**: The MACD line is above the signal line.
- **Bollinger Bands Condition**: Price is below the lower Bollinger Band.
- **Stochastic Condition**: %K and %D are below 50 (relaxed from below 20).

#### Sell Signal Conditions (`IsSellSignal()`):
The EA generates a sell signal with the reverse conditions:
- **MA Condition**: Short-term MA is below the long-term MA.
- **RSI Condition**: RSI is above 50 (a relaxed condition compared to overbought at 70).
- **MACD Condition**: The MACD line is below the signal line.
- **Bollinger Bands Condition**: Price is above the upper Bollinger Band.
- **Stochastic Condition**: %K and %D are above 50.

### Trade Execution
- **Stop Loss & Take Profit**: Based on multipliers (`SL_Multiplier`, `TP_Multiplier`) applied to the average true range (ATR) or another user-defined metric.
- **Order Placement**: Uses the `OrderSend()` function to execute buy or sell trades.
- **Lot Size Calculation**: The `CalculateLotSize()` function adjusts the lot size based on the selected trade size type (fixed, balance, equity).

## How to Use
1. Attach the EA to your EURUSD 5-minute chart.
2. Configure the input parameters to match your risk preferences (lot sizing, indicator settings, etc.).
3. Allow the EA to scan for trade signals based on the selected indicators and conditions.
4. The EA will automatically execute trades and manage them with dynamic SL/TP levels.

## Customization
The EA is designed to be highly customizable:
- Turn individual indicators on or off.
- Adjust indicator settings for different market conditions.
- Fine-tune the risk management strategy by configuring lot sizing and SL/TP levels.

## Notes
- Make sure to backtest the EA on historical data to understand its behavior before running it live.
- Monitor performance and adjust input parameters as necessary based on market conditions.

## License
This EA is provided "as is" without warranty of any kind. Use it at your own risk.

--- 

