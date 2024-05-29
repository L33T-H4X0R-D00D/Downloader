#!/bin/bash
#This script downloads a series of publically available DNS blocklists,
#strips them of unnecessary formatting, combines them, and deduplicates them.
#This file is overly verbose on purpose. It makes it easier for me to troubleshoot
#and easier for others to understand.

#Collect contents of lists into one file
curl $(cat urls.txt) >> biglist.txt

#Remove unnecessary blackhole 0.0.0.0 
sed 's/0.0.0.0//' biglist.txt >> clean1.txt

#Remove unnecessary blackhole 127.0.0.1
sed 's/127.0.0.1//' clean1.txt >> clean2.txt

#Remove triple octothorp comments
sed '/###/d' clean2.txt >> clean3.txt

#Create whitelist
sed -n '/#.*#/p' clean3.txt >> whitelist.txt

#Remove all comment lines that start with octothorp
sed '/^#/d' clean3.txt >> nocom.txt

#Remove blank lines
sed '/^$/d' nocom.txt >> nolines.txt

#Remove spaces
sed 's/ //' nolines.txt >> nospace.txt

#Dedupe lines
sort nospace.txt | uniq >> dedupe.txt

#Count the number of lines before dedupe
myvar1=$(sed -n '$=' nospace.txt)

#Count the number of lines after dedupe
myvar2=$(sed -n '$=' dedupe.txt)

#Find out how many lines were removed in dedupe
expr $myvar1 - $myvar2