###
# Visual Studio should publish a MSDEPLOY package to d:\phoursPkg dir
param (
  [Parameter(Mandatory=$true)][string]$profilename,
  [Parameter(Mandatory=$true)][string]$region,
  [Parameter(Mandatory=$true)][string]$bucketname,
  [Parameter(Mandatory=$true)][string]$stackname

)

$region = $region.ToLower()

$BLOC = Get-S3BucketLocation -BucketName $bucketname -ProfileName $profilename

Write-Host "bucket at: $BLOC."

if (([String]::IsNullOrEmpty($BLOC)) -and ($region -ne "us-east-1"))
{
    Write-Host "The Amazon S3 bucket you chose has to be in the same AWS region of you are creating the demo"
    exit 1
}
elseif (![String]::IsNullOrEmpty($BLOC) -and $BLOC -ne $region)
{
    Write-Host "The Amazon S3 bucket you chose has to be in the same AWS region where your demo is being created"
    exit 1
}

Set-DefaultAWSRegion $region

$CURDIR = Get-Location
$DATESUFFIX=[datetime]::Now.ToString('yy-MMM-dd-HHmm')
$TEMPLATES="${curdir}\templates"
$WEBAPP="${curdir}\WebAppCore2"
$TICK_SUFFIX=[datetime]::Now.Ticks.ToString().Substring([datetime]::Now.Ticks.ToString().Length -4)

#
# Packaging template.zip
#

$ZIPFILE = "${CURDIR}\templates.zip"
if (Test-Path $ZIPFILE) {
    Write-Host "Removing $ZIPFILE"
    Remove-Item $ZIPFILE
}
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory($TEMPLATES, $ZIPFILE)
Write-S3Object -bucketname $bucketname -Key singlecontainer-templates/templates.zip -File $ZIPFILE -ProfileName $profilename
Write-S3Object -bucketname $bucketname -KeyPrefix singlecontainer-templates -Folder $TEMPLATES -Recurse -ProfileName $profilename

#
# Preparing AWS CodeCommit
#
Write-Host "Creating AWS CodeCommit"

$AWSCC = Get-CCRepositoryList -ProfileName $profilename -Region $region.ToLower()
Write-Host $AWSCC
if ($AWSCC.RepositoryName -eq "WebAppSingleContainer")
{
    Remove-CCRepository -RepositoryName "WebAppSingleContainer" -Force -ProfileName $profilename
}

New-CCRepository -RepositoryName "WebAppSingleContainer" -RepositoryDescription "WebApp for .netcore2 cicd demo - Single Container" -ProfileName $profilename

#
# Preparing WebApp
#


if (Test-Path "${WEBAPP}\.git") {
    Write-Host "Removing .git"
    Remove-Item -Path "${WEBAPP}\.git" -Recurse -Force
}

Write-Host "Initializing git"
git init
git remote add origin ssh://git-codecommit.$region.amazonaws.com/v1/repos/WebAppSingleContainer
git add *
git commit -m "Inital commit"
git push origin master

#
# Creating Stack
#
Write-Host "Creating CloudFormation Stack"

$AWSCF = Get-CFNStackSetList -ProfileName $profilename

Write-Host $AWSCF

New-CFNStack -StackName $stackname ` 
    -TemplateURL https://s3.amazonaws.com/${bucketname}/singlecontainer-templates/ecs-dotnetcore-continuous-deployment.yaml `
    -Parameter @( @{ ParameterKey="SourceBucket"; ParameterValue="$bucketname"}, @{ ParameterKey="CodeCommitRepositoryName"; ParameterValue="WebAppSingleContainer" }) `
    -Capability "CAPABILITY_IAM" `
    -Region $region
