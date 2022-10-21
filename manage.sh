IMAGE_NAME="test-go-container-image"
IMAGE_REGISTRY="ghcr.io/chair6"
PLATFORM="linux/amd64"

OUTPUT_DIR="artifacts"

ACTIONS="build list run push extract clean scan-trivy scan-grype scan-docker scan-govulncheck scan-twistcli"
SEPARATOR=`printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -`

ACTION=$1
if [[ ! " $ACTIONS " =~ " $ACTION " ]]; then
    echo "USAGE: $0 [$(echo $ACTIONS | tr ' ' '|')]"
    exit
fi

# one-off actions
if [[ $ACTION == "clean" ]]
then
    docker rmi --force $(docker images --filter=reference="$IMAGE_NAME:*" -q)
    exit
fi
if [[ $ACTION == "scan-twistcli" ]]
then
    if [[ ! -v TWISTLOCK_URL ]]
    then
        echo "ERROR: to run twistcli scans, TWISTLOCK_URL / TWISTLOCK_USER / TWISTLOCK_PASSWORD env vars must be set"
        exit
    fi
fi

# per-Dockerfile actions
for FNAME in images/Dockerfile.*; do
    TARGET=`echo $FNAME | cut -d '.' -f 2-`
    if [[ $ACTION == "build" ]]
    then
        echo "Building image from $FNAME..."
        docker build . --platform $PLATFORM --file $FNAME --tag $IMAGE_NAME:$TARGET --tag $IMAGE_REGISTRY/$IMAGE_NAME:$TARGET
        docker images $IMAGE_NAME:$TARGET
        echo $SEPARATOR
    elif [[ $ACTION == "list" ]]
    then
        echo $IMAGE_NAME:$TARGET
    elif [[ $ACTION == "run" ]]
    then
        docker run --rm --platform $PLATFORM $IMAGE_NAME:$TARGET
    elif [[ $ACTION == "push" ]]
    then
        docker push $IMAGE_REGISTRY/$IMAGE_NAME:$TARGET
    elif [[ $ACTION == "extract" ]]
    then
        CONTAINER_ID=$(docker create $IMAGE_NAME:$TARGET)
        BINARY=`echo $TARGET | cut -d '-' -f 1`
        echo "extracting $BINARY binary from image to ./$OUTPUT_DIR/$TARGET"
        docker cp $CONTAINER_ID:/bin/$BINARY ./$OUTPUT_DIR/$TARGET
        echo $SEPARATOR
    elif [[ $ACTION == "scan-trivy" ]]
    then
        echo "Running trivy against $IMAGE_NAME:$TARGET"
        # note - not currently using --ignore-unfised
        trivy image --security-checks vuln --format json --output ./$OUTPUT_DIR/$TARGET-trivy.json $IMAGE_NAME:$TARGET
        echo $SEPARATOR
    elif [[ $ACTION == "scan-grype" ]]
    then
        echo "Running grype against $IMAGE_NAME:$TARGET"
        grype --output json --file ./$OUTPUT_DIR/$TARGET-grype.json $IMAGE_NAME:$TARGET
    elif [[ $ACTION == "scan-docker" ]]
    then
        echo "Running docker scan against $IMAGE_NAME:$TARGET"
        docker scan --json $IMAGE_NAME:$TARGET > ./$OUTPUT_DIR/$TARGET-docker.json
        echo $SEPARATOR
    elif [[ $ACTION == "scan-govulncheck" ]]
    then
        echo "Running govulncheck against local binary from $IMAGE_NAME:$TARGET"
        echo "(Make sure you've already run ./manage.sh extract to copy the binary out to $OUTPUT_DIR)"
        govulncheck -json ./$OUTPUT_DIR/$TARGET > ./$OUTPUT_DIR/$TARGET-govulncheck.json
        echo $SEPARATOR
    elif [[ $ACTION == "scan-twistcli" ]]
    then
        echo "Running twistcli against $IMAGE_NAME:$TARGET"
        twistcli images scan --address $TWISTLOCK_URL -u $TWISTLOCK_USER -p $TWISTLOCK_PASSWORD --output-file ./$OUTPUT_DIR/$TARGET-twistcli.json $IMAGE_NAME:$TARGET
    fi
done
