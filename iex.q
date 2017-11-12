main_url: "api.iextrading.com";
prefix: "HTTP/1.0\r\nhost:www.",main_url,"\r\n\r\n";

/ get last trade data for one or multiple securities
/ q)get_last_trade`aapl`ibm
/ sym  price  size time
/ ----------------------------------------------
/ AAPL 174.66 100  2017.11.10D20:59:58.008999936
/ IBM  149.18 300  2017.11.10D20:59:59.724999936  
get_last_trade:{[syms] 
  syms:$[1<count syms;"," sv string(upper syms);string(upper syms)];
  suffix: "GET /1.0/tops/last?symbols=";
  s2s: suffix,syms," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-3 + first result ss "symbol") _ result;
  data:-29!json;
  `sym xcol update symbol:`$symbol, time:"P"$string({"p"$1970.01.01D+1000000j*x}time) from data
 }
 
/ Get previous day summary for a security - high, low, open, close, vwap etc
/ q)get_prev_day_summary`aapl
get_prev_day_summary:{[sym]
  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/previous";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "symbol") _ result;
  json:"[",json,"]";
  data:-29!json;
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
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  txt:$[all "1d"=period;"minute";"date"];
  json:(-2 + first result ss txt) _ result;
  json:"[",json;
  data:-29!json;
  $[all "1d"=period;`sym`minute xcols update sym:`$sym,minute:"U"$minute from data;`sym`date xcols update sym:`$sym, date:"D"$date from data]
 }

/ Same as get_historical_summary but for a specific date
/ q)get_minutely_summary[`aapl;`20171103] 
get_minutely_summary:{[sym;date]
  sym:string(upper sym);
  date:string(date);
  suffix: "GET /1.0/stock/",sym,"/chart/date/",date;
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "minute") _ result;
  json:"[",json;
  data:-29!json;
  `sym`date`minute xcols update sym:`$sym, date:"D"$date, minute:"U"$minute from data
 }

/ Get information about a company such as exchange, industry, website, description, CEO etc
/ q) get_company_info`aapl 
get_company_info:{[sym]
  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/company";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "symbol") _ result;
  json:"[",json,"]";
  data:-29!json;
  `sym xcol update symbol:`$symbol from data
 }

/ Get key stats about a company such as market cap, beta, revenue, debt etc
/ q)get_company_info`aapl
 
get_key_stats:{[sym]
  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/stats";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "companyName") _ result;
  json:"[",json,"]";
  data:-29!json;
  `sym xcol `symbol xcols update latestEPSDate:"D"$latestEPSDate, shortDate:"D"$shortDate, exDividendDate:"D"$exDividendDate, symbol:`$symbol from data
 }

/ Get news relating to a company
/ q)get_company_news`aapl
get_company_news:{[sym]
  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/news";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "datetime") _ result;
  json:"[",json;
  data:-29!json;
  `sym xcols update sym:`$sym, datetime:"P"$datetime from data
 }
 
/ Get financial information of a company such as report date, gross profit, net income etc
/ q)get_company_financials`aapl
get_company_financials:{[sym]
  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/financials";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "symbol") _ result;
  data:-29!json;
  `sym xcols update sym:`$sym, reportDate:"D"$reportDate from data[`financials]
 }
 
/ Get earnings information of a company such as actual EPS, consensus EPS, estimated EPS etc
/ q)get_company_earnings`aapl
get_company_earnings:{[sym]
  sym:string(upper sym);
  suffix: "GET /1.0/stock/",sym,"/earnings";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "symbol") _ result;
  data:-29!json;
  `sym xcols update sym:`$sym, EPSReportDate:"D"$EPSReportDate, fiscalEndDate:"D"$fiscalEndDate from data[`earnings]
 }

/ Get most 'active' stocks with additional info such as close price, open price etc
/ q)get_most_active_stocks[]
get_most_active_stocks:{
  suffix: "GET /1.0/stock/market/list/mostactive";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "symbol") _ result;
  json:"[",json;
  data:-29!json;
  convert_epoch:{"p"$1970.01.01D+1000000j*x};
  `sym xcol update symbol:`$symbol, openTime:"P"$string(convert_epoch openTime), closeTime:"P"$string(convert_epoch closeTime), latestUpdate:"P"$string(convert_epoch latestUpdate), iexLastUpdated:"P"$string(convert_epoch iexLastUpdated), delayedPriceTime:"P"$string(convert_epoch delayedPriceTime) from data
 }

/ Get stocks with highest gains with additional info such as close price, open price etc
/ q)get_most_gainers_stocks[] 
get_most_gainers_stocks:{
  suffix: "GET /1.0/stock/market/list/gainers";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "symbol") _ result;
  json:"[",json;
  data:-29!json;
  convert_epoch:{"p"$1970.01.01D+1000000j*x};
  `sym xcol update symbol:`$symbol, openTime:"P"$string(convert_epoch openTime), closeTime:"P"$string(convert_epoch closeTime), latestUpdate:"P"$string(convert_epoch latestUpdate), iexLastUpdated:"P"$string(convert_epoch iexLastUpdated), delayedPriceTime:"P"$string(convert_epoch delayedPriceTime) from data
 }

/ Get stocks with most loss with additional info such as close price, open price etc
/ q)get_most_losers_stocks[] 
get_most_losers_stocks:{
  suffix: "GET /1.0/stock/market/list/losers";
  s2s: suffix," ",prefix;
  result:(`$":https://",main_url) s2s;
  json:(-2 + first result ss "symbol") _ result;
  json:"[",json;
  data:-29!json;
  convert_epoch:{"p"$1970.01.01D+1000000j*x};
  `sym xcol update symbol:`$symbol, openTime:"P"$string(convert_epoch openTime), closeTime:"P"$string(convert_epoch closeTime), latestUpdate:"P"$string(convert_epoch latestUpdate), iexLastUpdated:"P"$string(convert_epoch iexLastUpdated), delayedPriceTime:"P"$string(convert_epoch delayedPriceTime) from data
 }