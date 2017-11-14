/
#########################################################################################
# Author : Himanshu Gupta																
# Description: IEX is a new exchange that is slowly becoming popular. It provides a lot 
# of its data for free through its API. This code is a q/kdb+ wrapper to make it easier	
# to get data from IEX. 																
# IEX api URL: https://iextrading.com/developer/docs/#getting-started					
#########################################################################################
\

main_url: "api.iextrading.com";
prefix: "HTTP/1.0\r\nhost:www.",main_url,"\r\n\r\n";

/ Function for converting epoch time
convert_epoch:{"p"$1970.01.01D+1000000j*x};
 
/ Function for issuing GET request and getting the data in json format
get_data:{[main_url;suffix;prefix;char_delta;identifier]
  result: (`$":https://",main_url) suffix," ",prefix;
  (char_delta + first result ss identifier) _ result
 }
 
/ get last trade data for one or multiple securities
/ q)get_last_trade`aapl`ibm
/ sym  price  size time
/ ----------------------------------------------
/ AAPL 174.66 100  2017.11.10D20:59:58.008999936
/ IBM  149.18 300  2017.11.10D20:59:59.724999936  

get_last_trade:{[syms] 

  / This function can run for multiple securities.
  syms:$[1<count syms;"," sv string(upper syms);string(upper syms)];

  / Construct the GET request
  suffix: "GET /1.0/tops/last?symbols=",syms;

  / Parse json response and put into table
  data:.j.k get_data[main_url;suffix;prefix;-3;"symbol"];

  `sym xcol update symbol:`$symbol, time:"P"$string(convert_epoch time) from data
 }
 
/ Get previous day summary for a security - high, low, open, close, vwap etc
/ q)get_prev_day_summary`aapl

get_prev_day_summary:{[sym]

  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/previous";
  
  / Parse json response and put into table
  data: enlist .j.k get_data[main_url;suffix;prefix;-2;"symbol"];
  
  `sym xcol update symbol:`$symbol, date:"D"$date from data
 }

/ Get bucketed data for a security for different periods 
/ Available buckets are:
/ 	1d - 1 day
/   1m - 1 month
/   3m - 3 months
/   6m - 6 months
/   ytd - Year-to-date
/   1y - 1 year
/   2y - 2 years
/   5y - 5 years
/ q)get_historical_summary[`aapl;`1m] 

get_historical_summary:{[sym;period]

  sym:string(upper sym);
  period:string(period);
  suffix: "GET /1.0/stock/",sym,"/chart/",period;
  
  / Remove any text from response before 'minute' if period is 1d and 'date' otherwise
  txt:$[all "1d"=period;"minute";"date"];
  
  / Parse json response and put into table
  data:.j.k "[", get_data[main_url;suffix;prefix;-2;txt];
  
  / data has different schema for 1d vs other buckets
  $[all "1d"=period;
  `sym`minute xcols update sym:`$sym,minute:"U"$minute from data;
  `sym`date xcols update sym:`$sym, date:"D"$date from data]
 }

/ Same as get_historical_summary but for a specific date
/ q)get_minutely_summary[`aapl;`20171103] 

get_minutely_summary:{[sym;date]

  sym:string(upper sym);
  date:string(date);
  suffix: "GET /1.0/stock/",sym,"/chart/date/",date;
  
  / Parse json response and put into table
  data:.j.k "[",get_data[main_url;suffix;prefix;-2;"minute"];
  
  `sym`date`minute xcols update sym:`$sym, date:"D"$date, minute:"U"$minute from data
 }

/ Get information about a company such as exchange, industry, website, description, CEO etc
/ q)get_company_info`aapl 

get_company_info:{[sym]

  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/company";
  
  / Parse json response and put into table
  data: enlist .j.k get_data[main_url;suffix;prefix;-2;"symbol"];
  
  / Rename symbol to sym
  `sym xcol update symbol:`$symbol from data
 }

/ Get key stats about a company such as market cap, beta, revenue, debt etc
/ q)get_key_stats`aapl
 
get_key_stats:{[sym]

  sym:string(upper sym);  
  suffix: "GET /1.0/stock/",sym,"/stats";
  
  / Parse json response and put into table
  data: enlist .j.k get_data[main_url;suffix;prefix;-2;"companyName"];
  
  / Update data types and rename symbol column to sym
  `sym xcol `symbol xcols update latestEPSDate:"D"$latestEPSDate, shortDate:"D"$shortDate, exDividendDate:"D"$exDividendDate, symbol:`$symbol from data
 }

/ Get news relating to a company
/ q)get_company_news`aapl

get_company_news:{[sym]

  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/news";

  / Parse json response and put into table
  data:.j.k "[",get_data[main_url;suffix;prefix;-2;"datetime"];

  `sym xcols update sym:`$sym, datetime:"P"$datetime from data
 }
 
/ Get financial information of a company such as report date, gross profit, net income etc
/ q)get_company_financials`aapl

get_company_financials:{[sym]

  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/financials";
  
  / Parse json response and put into table
  data:.j.k get_data[main_url;suffix;prefix;-2;"symbol"];
  
  `sym xcols update sym:`$sym, reportDate:"D"$reportDate from data[`financials]
 }
 
/ Get earnings information of a company such as actual EPS, consensus EPS, estimated EPS etc
/ q)get_company_earnings`aapl

get_company_earnings:{[sym]

  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/earnings";
  
  / Parse json response and put into table
  data:.j.k get_data[main_url;suffix;prefix;-2;"symbol"];
  
  `sym xcols update sym:`$sym, EPSReportDate:"D"$EPSReportDate, fiscalEndDate:"D"$fiscalEndDate from data[`earnings]
 }

/ Get most 'active' stocks for last trade date with additional info such as close price, open price etc
/ q)get_most_active_stocks[]

get_most_active_stocks:{
   predefined_iex_lists_data[`mostactive]
 }

/ Get stocks with highest gains for last trade date with additional info such as close price, open price etc
/ q)get_most_gainers_stocks[] 

get_most_gainers_stocks:{
  predefined_iex_lists_data[`gainers]
 }

/ Get stocks with most loss for last trade date with additional info such as close price, open price etc
/ q)get_most_losers_stocks[] 

get_most_losers_stocks:{
  predefined_iex_lists_data[`losers]
 }

/ Helper function for getting 'lists' data from IEX
/ There are three types of lists: most active, gainers and losers 
predefined_iex_lists_data:{[list]
 
  list: string(list);
  suffix: "GET /1.0/stock/market/list/",list;

  / Parse json response and put into table
  data:.j.k "[",get_data[main_url;suffix;prefix;-2;"symbol"];
  
  `sym xcol update symbol:`$symbol, openTime:"P"$string(convert_epoch openTime), closeTime:"P"$string(convert_epoch closeTime), latestUpdate:"P"$string(convert_epoch latestUpdate), iexLastUpdated:"P"$string(convert_epoch iexLastUpdated), delayedPriceTime:"P"$string(convert_epoch delayedPriceTime) from data
 }