#!/bin/bash

if [[ ! -n "$1" ]] || [[ "$#" -lt "6" ]]; then
  echo "Use: createApp --bucket yourbucketname --stack stackname --region awsregion --profile awsprofile"
  echo "if you omit --profile parameter the script will use the user's default AWS profile"
  exit 1
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -b|--bucket)
    BUCKET="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--region)
    AWSREGION="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--stack)
    STACKNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--profile)
    PROFILE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# NO EDIT IS REQUIRED BEYOND THIS PART

BLOC="$(aws s3api get-bucket-location --bucket ${BUCKET} --output text)"
if [[ "$BLOC" != "$AWSREGION" ]]; then
   echo "The Amazon S3 bucket you chose has to be in the same AWS region where your demo is being created"
   exit 1
elif [[ "$BLOC" == "None" ]] && [[ "$AWSREGION" != "us-east-1" ]]; then
   echo "The Amazon S3 bucket you chose has to be in the same AWS region of you are creating the demo"
   exit 1
fi

if [[ "${#AWSPROFILE}" > 1 ]]; then
    export AWS_PROFILE="$AWSPROFILE" 
else
    echo "using default profile"
fi

read curdir <<< $(pwd)
DATESUFFIX=$(date +%Y-%b-%d-%H%M)
TEMPLATES="${curdir}"/templates
NGINX="${curdir}"/nginx
WEBAPP="${curdir}"/WebAppCore2

DATE_SUFFIX=$(date +%y%m%d-%H%M)
DATE_TICKS=$(date +%s)
TICK_SUFFIX=${DATE_TICKS:6:4}

#
# Packaging template.zip
#
echo "Packaging template.zip"
cd ${TEMPLATES}
pwd
rm *.zip
zip templates *
aws s3 cp templates.zip s3://${BUCKET}/aspnetcognito-template/templates.zip
aws s3 cp . s3://${BUCKET}/aspnetcognito-template/ --recursive --exclude "*.zip"

#
# Packaging nginx.zip
#
echo "Packaging nginx.zip"
cd ${NGINX}
pwd
rm *.zip
zip nginx *
aws s3 cp nginx.zip s3://${BUCKET}/aspnetcognito-template/nginx.zip

#
# Preparing AWS CodeCommit
#
echo "Packaging AWS CodeCommit"

AWSCC="$(aws codecommit list-repositories --region ${AWSREGION}| grep WebAppCognito)"
if [[ "${#AWSCC}" > 1 ]]; then
   aws codecommit delete-repository --repository-name WebAppCognito --region ${AWSREGION}
   sleep 2s
fi

aws codecommit create-repository --repository-name WebAppCognito \
   --repository-description "WebApp for .netcore2 Cognito Integration" \
   --region ${AWSREGION}
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

#
# Preparing WebApp
#

cd ${WEBAPP}
rm -r -f .git

REGIONENDPOINT="$(echo $AWSREGION | sed -E s/-//g | awk '{print toupper(substr($0,0,3))tolower(substr($0,4))}')"
echo "Preparing app to run on ${AWSREGION}"
sed -i -E s/"aws-region"/"${AWSREGION}"/g ${WEBAPP}/appsettings.json
sed -i -E s/"aws-region"/"${AWSREGION}"/g ${WEBAPP}/appsettings.Development.json

echo "Initializing git"
git init
git config --global user.email "cicddemo@amazon.com"
git config --global user.name "devuser"
git remote add origin ssh://git-codecommit.${AWSREGION}.amazonaws.com/v1/repos/WebAppCognito
git add *
git commit -m "Inital commit"
git push origin master

#
# Creating Stack
#
echo "Creating CloudFormation Stack"
AWSCF="$(aws cloudformation list-stacks --region ${AWSREGION} | grep ${STACKNAME} --count)"
if [[ "${#AWSFC}" > 1 ]]; then
   aws cloudformation delete-stack --stack-name ${STACKNAME} --region ${AWSREGION}
   echo "A delete-stack was issued, pls re-run the script once the stack is deleted or execute the script with a diferent stackname"
   exit 1
fi

aws cloudformation create-stack --stack-name ${STACKNAME} \
   --template-url https://s3.amazonaws.com/${BUCKET}/aspnetcognito-template/ecs-dotnetcore-continuous-deployment.yaml \
   --parameters ParameterKey=SourceBucket,ParameterValue=${BUCKET} --capabilities CAPABILITY_IAM \
   --region us-west-2 --profile ${PROFILE}
