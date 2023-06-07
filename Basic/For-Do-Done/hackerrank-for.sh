# https://www.hackerrank.com/challenges/bash-tutorials---looping-with-numbers/problem
for num in {1..50}
do
echo $num
done


# https://www.hackerrank.com/challenges/bash-tutorials---looping-and-skipping/problem
for num in {1..99}
do
    if [[ $num%2 -ne 0 ]]
    then
        echo $num
    fi
done
