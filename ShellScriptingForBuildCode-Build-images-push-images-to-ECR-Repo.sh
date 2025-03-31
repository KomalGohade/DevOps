#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Function to display messages in color
msg() {
    echo -e "\e[1m\e[34m$1\e[0m"
}
#Reminder to git pull and take appropriate action
read -p "Did you take pull from git?(yes/no) " gitPull

# Prompt user to reming adding the sql script at given location
read -p "Did you add sql script to sql_scripts folder? (yes/no/na): " script

# Prompt user to select environment
read -p "Select environment (prod/uat/dt): " environment

# Build Maven project skipping tests
msg "Building Maven project..."
mvn clean install -DskipTests

case "$environment" in
    uat)
        PROFILE="uat"
        TAG_REPO="dtnprd/augbackend"
        ;;
    prod)
        PROFILE="prod"
        TAG_REPO="dtp/augbackend"
        ;;
    dt)
        PROFILE="uat"
        TAG_REPO="dtp/augbackend"
        ;;
    *)
        echo "Invalid environment selection"
        exit 1
        ;;
esac



# Build Docker image
echo "Building Docker image..."
docker build  --build-arg PROFILE="$PROFILE" \
        -t dtp/augbackend .

#Login to aws ecr
sudo su ihisecr -c "aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 438132676559.dkr.ecr.ap-southeast-1.amazonaws.com"

# Store Docker tag in a variable
TAG=438132676559.dkr.ecr.ap-southeast-1.amazonaws.com/$TAG_REPO:$(date +%Y%m%d%H%M)

#Change user to ihisecr
sudo -u ihisecr /bin/bash<<EOF

#Change docker config to ihisecr's config
export DOCKER_CONFIG=/home/ihisecr/.docker

# Tag and push Docker image
echo "Tagging and pushing Docker image..."
docker tag dtp/augbackend $TAG
docker push $TAG

EOF
msg "Image successfully tagged and pushed:$TAG"
