#!/bin/bash
#This script downloads a series of publicly available DNS block lists, strips them of unnecessary formatting, combines them, and de-duplicates them. This file is overly verbose on purpose. It makes it easier for me to troubleshoot and easier for others to understand.

#Requirements
#This script requires a source list, in the same directory, named "urls.txt".  Place one target url per line. If you have domains you wish to ensure are included in the final list, put them in a file named blacklist.txt.  One domain per line.
#urls.txt
#whitelist.txt

#Output
#A text file named "current.txt" is created with the cleaned and sorted results. This can be fed into your Pihole or DNSBL source list.  Some list providers include helpful domains to whitelist as comments. These entries are stored in "suggested.txt". 

#Prep section
#Create the date variable.
nowvar="$(date +"%F-%H%M")"
#Start the log with the date and time.
echo $nowvar >> log/log.txt
#Create working directories
mkdir -p log old working >> log/log.txt
#Move and rename the current list to the old directory
mv current.txt old/$nowvar.txt >> log/log.txt
#Clean up previous working files. By doing it at the beginning the previous working files are left for debug.
rm -v suggested.txt working/biglist.txt working/clean1.txt working/clean2.txt working/clean3.txt working/nocom.txt working/dedupe.txt working/nolines.txt working/nospace.txt >> log/log.txt

#Work section
#Collect contents of lists into one file
curl $(cat urls.txt) >> working/biglist.txt
#Include entries in the blacklist file
cat blacklist.txt >> working/biglist.txt
#Remove unnecessary blackhole 0.0.0.0
sed 's/0.0.0.0//' working/biglist.txt >> working/clean1.txt
#Remove unnecessary blackhole 127.0.0.1
sed 's/127.0.0.1//' working/clean1.txt >> working/clean2.txt
#Remove triple octothorp comments
sed '/###/d' working/clean2.txt >> working/clean3.txt
#Capture list author suggestions
sed -n '/#.*#/p' working/clean3.txt >> suggested.txt
#Remove all comment lines that start with octothorp
sed '/^#/d' working/clean3.txt >> working/nocom.txt
#Deduplicate lines
sort working/nocom.txt | uniq >> working/dedupe.txt
#Remove blank lines
sed '/^$/d' working/dedupe.txt >> working/nolines.txt
#Remove spaces
sed 's/ //' working/nolines.txt >> working/nospace.txt
#Remove entries on the whitelist
LC_ALL=C grep -Fvxf whitelist.txt working/nospace.txt >> current.txt

#Logging section
#Counting lines in each of the working files. 
bigvar=$(sed -n '$=' working/biglist.txt)
echo $bigvar entries in download >> log/log.txt
cl1var=$(sed -n '$=' working/clean1.txt)
echo $cl1var entries post 0.0.0.0 cull >> log/log.txt
cl2var=$(sed -n '$=' working/clean2.txt)
echo $cl2var entries post 127.0.0.1 cull >> log/log.txt
cl3var=$(sed -n '$=' working/clean3.txt)
echo $cl3var entries post triple octothorp cull >> log/log.txt
ncvar=$(sed -n '$=' working/nocom.txt)
echo $ncvar entries post comments cull >> log/log.txt
livar=$(sed -n '$=' working/nolines.txt)
echo $livar entries post blank lines cull >> log/log.txt
spvar=$(sed -n '$=' working/nospace.txt)
echo $spvar entries post space cull >> log/log.txt
ddvar=$(sed -n '$=' current.txt)
echo $ddvar entries post de-duplication >> log/log.txt
#Count how many lines were removed during de-duplication.
rmvar=$(expr $ncvar - $ddvar)
echo $rmvar entries de-duplicated >> log/log.txt
wlvar=$(sed -n '$=' whitelist.txt)
echo $wlvar entries in whitelist >> log/log.txt
blvar=$(sed -n '$=' blacklist.txt)
echo $blvar entries in blacklist >> log/log.txt
sgvar=$(sed -n '$=' suggested.txt)
echo $sgvar entries in suggested >> log/log.txt
echo File sizes >> log/log.txt
du -h current.txt whitelist.txt blacklist.txt suggested.txt log/log.txt old >> log/log.txt
echo >> log/log.txt