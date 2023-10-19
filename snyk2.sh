#!/bin/bash
source constants.sh

IMAGE_NAME_ONE=$1
IMAGE_NAME_TWO=$2
NOCACHE=false

# if 3rd arg is "--nocache" set NOCACHE to true
if [ "$3" == "--nocache" ]; then
  NOCACHE=true
fi

mkdir -p .snyk2

#get image ID for IMAGE_NAME_ONE
IMAGE_ID_ONE=$(docker image inspect $IMAGE_NAME_ONE --format='{{json .Id}}')
IMAGE_ID_TWO=$(docker image inspect $IMAGE_NAME_TWO --format='{{json .Id}}')

# remove the leading "sha256:" from the ID
IMAGE_ID_ONE=${IMAGE_ID_ONE:7}
IMAGE_ID_TWO=${IMAGE_ID_TWO:7}

#if IMAGE_ID_ONE is not empty, check .snyk2 for a file with the ID name
if [ ! -z "$IMAGE_ID_ONE" ]; then
  if [ -f ".snyk2/${IMAGE_ID_ONE}.json" ] && ! $NOCACHE; then
    echo "Using cached Snyk scan for $IMAGE_NAME_ONE"
    IMAGE_JSON_ONE=".snyk2/${IMAGE_ID_ONE}.json"
    IMAGE_NAME_ONE="${IMAGE_NAME_ONE}_(cached)"
  fi
else
  echo "Image $IMAGE_NAME_ONE not found locally, please pull or build it first"
  exit 1
fi

if [ ! -z "$IMAGE_ID_TWO" ]; then
  if [ -f ".snyk2/${IMAGE_ID_TWO}.json" ] && ! $NOCACHE; then
    echo "Using cached Snyk scan for $IMAGE_NAME_TWO"
    IMAGE_JSON_TWO=".snyk2/${IMAGE_ID_TWO}.json"
    IMAGE_NAME_TWO="${IMAGE_NAME_TWO}_(cached)"
  fi
else
  echo "Image $IMAGE_NAME_TWO not found locally, please pull or build it first"
  exit 1
fi



if [[ ! -f $IMAGE_JSON_ONE ]]; then
  echo "Running snyk container test on $IMAGE_NAME_ONE"
  snyk container test $IMAGE_NAME_ONE --exclude-app-vulns --group-issues --json > .snyk2/$IMAGE_ID_ONE.json &
fi

if [[ ! -f $IMAGE_JSON_TWO ]]; then
  echo "Running snyk container test on $IMAGE_NAME_TWO"
  snyk container test $IMAGE_NAME_TWO --exclude-app-vulns --group-issues --json >.snyk2/$IMAGE_ID_TWO.json &
fi

wait
echo

./scandiff.sh .snyk2/${IMAGE_ID_ONE}.json .snyk2/${IMAGE_ID_TWO}.json "$IMAGE_NAME_ONE" "$IMAGE_NAME_TWO"
