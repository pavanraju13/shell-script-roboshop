#!/bin/bash

#This script is to print 1 to 20 numbers.

for i in {1..20}
do

echo "Number is: $i"

done

i=$1
if [ $1 -lt 30 ]
then
echo "Given number $1 is less than 30"
else
echo "Given number $1 is greater than or equal to 30"
fi
