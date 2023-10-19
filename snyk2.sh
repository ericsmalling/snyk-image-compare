#!/bin/bash
source constants.sh

IMAGE_ONE=$1
IMAGE_TWO=$2

#run snyk container test in parallel for both images and capture json output from both
MY_PID=$$

# if IMAGE_ONE ends in .json then use that file otherwise assume it's an image name
if [[ $IMAGE_ONE == *.json ]]; then
  echo "Using $IMAGE_ONE as JSON file snyk.${MY_PID}a.json"
  cp $IMAGE_ONE snyk.${MY_PID}a.json
else
  echo "Running snyk container test on $IMAGE_ONE"
  snyk container test $IMAGE_ONE --exclude-app-vulns --group-issues --json > snyk.${MY_PID}a.json &
fi

# if IMAGE_TWO ends in .json then use that file otherwise assume it's an image name
if [[ $IMAGE_TWO == *.json ]]; then
  echo "Using $IMAGE_ONE as JSON file"
  cp $IMAGE_TWO snyk.${MY_PID}b.json
else
  echo "Running snyk container test on $IMAGE_TWO"
  snyk container test $IMAGE_TWO --exclude-app-vulns --group-issues --json > snyk.${MY_PID}b.json &
fi

wait

./scandiff.sh snyk.${MY_PID}a.json snyk.${MY_PID}b.json $IMAGE_ONE $IMAGE_TWO
