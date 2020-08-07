# find shortest time series length

# shortest function returns a vector of the row number of the shortest token, what word the token is and which speaker the token is from
# arguments: data frame and the word column label as a string (word with repetition number)

shortest<- function(m, wordcol){
  min<- 1000
  word<- ''
  speaker<- ''
  words<- levels(droplevels(m[, wordcol]))
  speakers<- levels(droplevels(m[,'Speaker']))
  for (s in 1:length(speakers)){
    for (i in 1:length(words)){
      currentdf<- m[m[, wordcol] == words[i] & m$Speaker == speakers[s],]
      currentlen<- nrow(currentdf)
      if (currentlen < min && currentlen != 0){
        min<- currentlen 
        word<- words[i]
        speaker<- speakers[s]
      }
    }
  }
  return(c(min, word, speaker))
}

# trim time series

# trimdf returns the trimmed data frame
# arguments: untrimmed data frame, number of rows to keep, word column label (with repetition)

trimdf<- function(m, trimnum, wordcol){
  words<- levels(droplevels(m[, wordcol]))
  speakers<- levels(droplevels(m[,'Speaker']))
  for (s in 1:length(speakers)){
    for (i in 1:length(words)){
      currentdf<- m[m[, wordcol] == words[i] & m[, 'Speaker'] == speakers[s],]
      if (nrow(currentdf) >0 ){
        if (i == 1 && s == 1){
          trimmed<- currentdf[1:trimnum,]
        }
        else{
          trimmedInt<- currentdf[1:trimnum,]
          trimmed<- rbind(trimmed, trimmedInt)
        }
      }
    }
  }
  row.names(trimmed)<- NULL
  return(trimmed)
}