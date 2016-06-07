##dazhongdianping

library(RCurl)
library(XML)
library("plyr")


URL<-"http://t.dianping.com/list/shanghai-category_1?"
page<-1:49
urlist<-paste("http://t.dianping.com/list/shanghai-category_1?pageIndex=",page,sep="")
urllist<-c(URL,urlist)
 
#伪造报头
myheader<-c("User-Agent"="Mozilla/5.0 (Windows;U;Windows NT 5.1;zh-CN;rv:1.9.1.6)",
            "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language"="en-us",
            "Connection"="keep-alive",
            "Accept-Charset"="GB2312,utf-8;q=0.7,*;q=0.7")
#店铺名称
dp_name<-c("")

#原价
last_price<-c("")

#优惠价格
now_price<-c("")

#备注
remarks<-c("")

#销售量
sales<-c("")

for(url in urllist){
  webpage<-getURL(url,httpheader=myheader,.encoding="UTF-8")
  pagetree<-htmlTreeParse(webpage,encoding="utf-8",error=function(...){},useInternalNodes=TRUE,trim=TRUE)
  temp_name<-xpathSApply(pagetree,"//*/a[@class='tg-floor-title']/h3",xmlValue)
  dp_name<-c(dp_name,temp_name)
  temp_price<-xpathSApply(pagetree,"//*/span[@class='tg-floor-price-old']",xmlValue)
  last_price<-c(last_price,temp_price)
  temp_now_price<-xpathSApply(pagetree,"//*/span[@class='tg-floor-price-new']",xmlValue)
  now_price<-c(now_price,temp_now_price)
  temp_remarks<-xpathSApply(pagetree,"//*/a[@class='tg-floor-title']/h4",xmlValue)
  remarks<-c(remarks,temp_remarks)
  temp_sales<-xpathSApply(pagetree,"//*/span[@class='tg-floor-sold']",xmlValue)
  sales<-c(sales,temp_sales)
}


#对爬取的数据进行处理

dp_name<-dp_name[2:2001]

last_price<-unlist(strsplit(unlist(strsplit(last_price,"\n"))[c(F,T,F)],"¥"))[c(F,T)]

now_price<-unlist(strsplit(unlist(strsplit(now_price,"\n"))[c(F,T,F)],"¥"))[c(F,T)]

remarks<-paste(gsub(" ","",unlist(strsplit(remarks,"\n"))[c(T,T,F)])[seq(1,3999,2)],gsub(" ","",unlist(strsplit(remarks,"\n"))[c(T,T,F)])[seq(2,4000,2)])

sales<-gsub(" ","",unlist(strsplit(sales,"\n"))[c(F,T,F)])

sales<-as.numeric(unlist(strsplit(sales,"已售"))[c(F,T)])


#写入excel文件中保存

content<-data.frame(dp_name,last_price,now_price,remarks,sales)

names(content)<-c("names","pre_price","new_price","remarks","sales")

write.csv(content,file="dianping_new.csv")


#把数据写入数据库
library(RMySQL)

conn<-dbConnect(MySQL(),dbname='dazhongdianping',username='root',password='')

dbWriteTable(conn,'Info',content)

dbReadTable(conn,'Info')

Info<-dbGetQuery(conn,'select * from Info limit 100')

Topsales<-dbGetQuery(conn,'select * from Info order by sales desc')

Repeat<-dbGetQuery(conn,'select sales from Info group by sales having count(*)>1')

Repeat2<-dbGetQuery(conn,'select * from Info where sales in(select sales from Info group by sales having count(sales)=2) order by sales desc')

dbDisconnect(conn)





