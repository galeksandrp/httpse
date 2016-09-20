#!/bin/bash

# Step 1: Find all subdomains w/ false-positives
python2.7 Sublist3r/sublist3r.py -d $1 > cd1.tmp.txt
tail -n +23 cd1.tmp.txt | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" > cd1.txt
rm cd1.tmp.txt

# Step 2: Sort out false positives
while read LINE; do
  curl -o /dev/null -A "HTTPS/SSL coverage scan; Internet security scanning project." --max-time 1 --silent --head --write-out '%{http_code}' "$LINE" >> cd2.txt
  echo " $LINE" >> cd2.txt
done < cd1.txt

grep -v "000 " cd2.txt > cd3.tmp.txt
cut -f 2 -d ' ' cd3.tmp.txt > cd3.txt
rm cd3.tmp.txt

# Step 3: Compile ruleset
python3 p1.py $1

# Optional: clean, comment out if debugging
rm cd1.txt cd2.txt cd3.txt