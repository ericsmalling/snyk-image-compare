#!/bin/bash
source constants.sh

function formatDifference() {
  val1=$1
  val2=$2
  if [ $val1 -eq $val2 ]; then
    printf " %5s" $val1
  elif [ $val1 -gt $val2 ]; then
    printf "${COLOR_GREEN} %5s${COLOR_RESET}" "-$(($val1-$val2))"
  else
    printf "${COLOR_RED} %5s${COLOR_RESET}" "+$(($val2-$val1))"
  fi
}

# if two arguments are passed, compare the two files
if [ $# -eq 4 ]; then
  JSON_ONE=$(cat $1)
  NAME_ONE=$(echo $3 | tr '_' ' ')
  JSON_TWO=$(cat $2)
  NAME_TWO=$(echo $4 | tr '_' ' ')
elif [ $# -eq 2 ]; then
  JSON_ONE=$(cat $1)
  NAME_ONE=$(basename $1)
  JSON_TWO=$(cat $2)
  NAME_TWO=$(basename $2)
elif [ $# -eq 1 ]; then
  JSON_ONE=$(cat -)
  NAME_ONE="STDIN"
  JSON_TWO=$(cat $1)
  NAME_TWO=$(basename $1)
else
  echo "
Usage: $0 <file1> <file2>
       $0 <file2> (stdin)
"
  exit 1
fi

echo "Comparing ${NAME_ONE} to ${NAME_TWO}..."

summary_one=$(echo $JSON_ONE | jq -c '.dependencyCount as $dependencies | [ .vulnerabilities[].severity] | reduce .[] as $sev ({}; .[$sev] +=1) | { dependencies: $dependencies, low: (.low // 0), medium: (.medium // 0), high: (.high // 0), critical: (.critical // 0)} | .total = .low + .medium + .high + .critical ')
summary_two=$(echo $JSON_TWO | jq -c '.dependencyCount as $dependencies | [ .vulnerabilities[].severity] | reduce .[] as $sev ({}; .[$sev] +=1) | { dependencies: $dependencies, low: (.low // 0), medium: (.medium // 0), high: (.high // 0), critical: (.critical // 0)} | .total = .low + .medium + .high + .critical ')

ttl_one=$(echo $summary_one | jq -r '.total')
critical_one=$(echo $summary_one | jq -r '.critical')
high_one=$(echo $summary_one | jq -r '.high')
medium_one=$(echo $summary_one | jq -r '.medium')
low_one=$(echo $summary_one | jq -r '.low')

ttl_two=$(echo $summary_two | jq -r '.total')
critical_two=$(echo $summary_two | jq -r '.critical')
high_two=$(echo $summary_two | jq -r '.high')
medium_two=$(echo $summary_two | jq -r '.medium')
low_two=$(echo $summary_two | jq -r '.low')

# set C1WIDTH to the length of the longest image name
C1WIDTH=$(echo -e "${NAME_ONE}\n${NAME_TWO}" | awk '{ print length }' | sort -nr | head -n1)

printf "${UNDERLINE}%${C1WIDTH}s : ${BOLD}${COLOR_PURPLE}%6s ${COLOR_RED}%6s ${COLOR_YELLOW}%6s ${COLOR_WHITE}%6s ${COLOR_RESET}${UNDERLINE}: %6s${COLOR_RESET} \n" "Image" "Crit" "High" "Med" "Low" "TTL"
printf "%${C1WIDTH}s : ${BOLD}${COLOR_PURPLE}%6d ${COLOR_RED}%6d ${COLOR_YELLOW}%6d ${COLOR_WHITE}%6d ${COLOR_RESET}: %6d \n" "$NAME_ONE" $critical_one $high_one $medium_one $low_one $ttl_one
printf "%${C1WIDTH}s : ${BOLD}${COLOR_PURPLE}%6d ${COLOR_RED}%6d ${COLOR_YELLOW}%6d ${COLOR_WHITE}%6d ${COLOR_RESET}: %6d \n" "$NAME_TWO" $critical_two $high_two $medium_two $low_two $ttl_two
echo "${COLOR_WHITE}$(printf "%${C1WIDTH}s" "diff") :${COLOR_RESET} $(formatDifference $critical_one $critical_two) ${COLOR_RED}$(formatDifference $high_one $high_two) ${COLOR_YELLOW}$(formatDifference $medium_one $medium_two) ${COLOR_WHITE}$(formatDifference $low_one $low_two) ${COLOR_RESET}${COLOR_WHITE}:${COLOR_RESET} $(formatDifference $ttl_one $ttl_two)"

