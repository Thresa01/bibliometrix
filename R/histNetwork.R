#' Historical co-citation network
#'
#' \code{histNetwork} creates a historical citation network from a bibliographic
#' data frame.
#'
#' @param M is a bibliographic data frame obtained by the converting function
#'   \code{\link{convert2df}}. It is a data matrix with cases corresponding to
#'   manuscripts and variables to Field Tag in the original SCOPUS and Clarivate
#'   Analitics' Web of Knowledge file.
#' @param min.citations is an integer. It sets the minimum number of citations 
#'   for the documents included in the analysis. The default is \code{min.citations = 0}.
#' @param sep is the field separator character. This character separates strings
#'   in CR column of the data frame. The default is \code{sep = ";"}.
#' @return \code{histNetwork} returns an object of \code{class} "list"
#'   containing the following components:
#'
#'   \tabular{lll}{ NetMatrix \tab  \tab the historical co-citation network
#'   matrix\cr histData \tab      \tab the set of n most cited references\cr M
#'   \tab      \tab the bibliographic data frame}
#'
#'
#' @examples
#' data(scientometrics)
#'
#' histResults <- histNetwork(scientometrics, min.citations = 10, sep = ";")
#'
#'
#' @seealso \code{\link{convert2df}} to import and convert an ISI or SCOPUS
#'   Export file in a bibliographic data frame.
#' @seealso \code{\link{summary}} to obtain a summary of the results.
#' @seealso \code{\link{plot}} to draw some useful plots of the results.
#' @seealso \code{\link{biblioNetwork}} to compute a bibliographic network.
#'
#' @export

histNetwork<-function(M, min.citations = 0, sep = ";"){
  
  #if (M$DB[1]!="ISI"){cat("\nSorry, but for the moment histNetwork works only with WoS collections\n\n")
  #  return()}
  M$TC=as.numeric(M$TC)
  if (!("SR" %in% names(M))){M=metaTagExtraction(M,Field="SR")} 
  M=M[order(M$PY),]
  
  M2=M[M$TC>=min.citations,]
  if (dim(M2)[1]==0){cat("\nNo document has a number of citations above the fixed threshold\n");return(NULL)}
  
  
  N=dim(M2)[1]
  N2=dim(M)[1]
  rows=c(1:N2)
  
  lCit=Matrix(0, N,N2)
  
  switch(M$DB[1],
     ISI={
       ## matching by SR
            for (i in 1:N){
                if (i%%100==0 | i==N) cat("Articles analysed  ",i,"\n")
                x=M2$SR[i]
                Year=M2$PY[i]
                pos = grep(x, M$CR[M$PY>=Year])
                pos = rows[M$PY>=Year][pos]
                if ("DI" %in% names(M)){
                  if (!is.na(M2$DI[i])){
                    pos2 = grep(M2$DI[i],M$CR[M$PY>=Year],fixed=TRUE)
                    pos2 = rows[M$PY>=Year][pos2]
                    pos=unique(pos,pos2)}
                }
    
                if (length(pos)>0){
                  lCit[i,pos]=1
                }
            }
         },
    SCOPUS={
      ## matching by title and year
      TI=paste(M2$TI," ","\\(",M2$PY,"\\)",sep = "")
      TIb=paste("\\(",M2$PY,"\\)"," ",M2$TI,sep = "")
      for (i in 1:N){
        if (i%%100==0 | i==N) cat("Articles analysed  ",i,"\n")
      
        x=TI[i]
        y=TIb[i]
        Year=M2$PY[i]
        pos = grep(x, M$CR[M$PY>=Year])
        pos = rows[M$PY>=Year][pos]
        pos2 = grep(y, M$CR[M$PY>=Year])
        pos2 = rows[M$PY>=Year][pos2]
        pos=unique(pos,pos2)
        if (length(pos)>0){
          lCit[i,pos]=1
        }
      }
  })
  
  LCS=rowSums(lCit)

  ### to assure that LCS cannot be greater than TC
  ind=which(LCS>M2$TC)
  LCS[ind]=M2$TC[ind]
  ####
  
  M2$LCS=LCS
  row.names(lCit)=M2$SR
  colnames(lCit)=M$SR
  
  lCit=lCit[,(M$SR %in% M2$SR)]
  
 
  if (!("DI" %in% names(M2))){M2$DI=NA}
  df=data.frame(Paper=M2$SR,DOI=M2$DI,Year=M2$PY,LCS=LCS,GCS=M2$TC,stringsAsFactors = F)
  df=df[order(df$Year),]  
  

row.names(df)=paste(df$Year,rep("-",dim(df)[1]),1:dim(df)[1])

results=list(NetMatrix=t(lCit),histData=df,M=M2,LCS=LCS)

return(results)
}
