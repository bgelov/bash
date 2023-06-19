# https://www.hackerrank.com/challenges/text-processing-sort-1/problem
sort


# https://www.hackerrank.com/challenges/text-processing-sort-2/problem
# Sort reverse
sort -r


# https://www.hackerrank.com/challenges/text-processing-sort-3/problem
# Sort numeric
sort -n


# https://www.hackerrank.com/challenges/text-processing-sort-4/problem
# Sort numeric desc
sort -nr


# https://www.hackerrank.com/challenges/text-processing-sort-5/problem
# Revers sort 2 numeric column with tab delimetr
sort -rnk 2 -t $'\t'
# -r - For reverse order
# -n - Numerical sort
# -k - Column ordering
# -t - Tab separted indicator


# https://www.hackerrank.com/challenges/text-processing-sort-6/problem
sort -nk 2 -t $'\t'


# https://www.hackerrank.com/challenges/text-processing-sort-7/problem
# with pipe delimetr
sort -rnk 2 -t $'|'
