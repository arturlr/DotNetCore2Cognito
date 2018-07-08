
# How to configure configure a Cognito User Pool.

Create a new Cognito User Pool in one of the AWS regions and make sure to select 'Step through settings' instead of 'Review defaults'.

On the Attributes page ensure you select Email address or phone number for how you want end users to sign in.

Also make sure you check **name**, **given_name**, **family_name** as attributes that are required. Keep clicking next until the App clients section and click Add an app client

Give your App client name a name and uncheck Generate client secret and check Enable sign-in API for server-based authentication (ADMIN_NO_SRP_AUTH) and click Create App Client.

After your Cognito User Pool is created take note of the Pool Id and Pool ARN .

### Importing users into cognito

If this was a new web application your users would likely sign-up themselves and would have a user record created in the Cognito User Pool. In the case where you want to migrate an existing user directory to Cognito you can leverage a Import Users tool located in the Users and groups section.

Before you can import users into your Cognito User Pool you will need to setup to configure an IAM role. Follow the instructions [here](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-using-import-tool-cli-cloudwatch-iam-role.html) to create the required role.

### Publishing the application using AWS CodePipeline CI/CD

From a windows maching with the [Windows CLI](https://aws.amazon.com/premiumsupport/knowledge-center/install-aws-cli-windows/) installed, execute the powershell script prepCicd.ps1. It will create the AWS CodeCommit Repository, AWS CodeBuild and AWS CodeDeploy that will deploy the application for you automatically. 