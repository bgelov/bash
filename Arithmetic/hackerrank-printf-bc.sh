# https://www.hackerrank.com/challenges/bash-tutorials---arithmetic-operations/problem
read expr

# bc with scale cut end of number. Not round it.
# echo "scale = 3; $expr" | bc -l

printf "%.3f" $(echo "$expr" | bc -l)
