# Dynamic DNS for Ubiquiti UniFi Gateways and Amazon AWS Route53 Service

This project enables dynamic dns support for AWS Route53 hosted DNS when using a Unifi gateway, such a Dream Machine Pro.

## About

AWS Route53 is a managed DNS service offering through Amazon AWS.  It is highly configurable and performant, and supports many advanced DNS features, including some that are proprietary.  However it does not have an out of the box turnkey solution for Dynamic DNS as commonly found in home and small business networks.

A Ubiquiti UniFi gateway is a multipurpose internet router.  It has native support for many different dynamic DNS service providers.  However it does not natively support dynamic DNS using AWS Route53.  UniFi gateways enable dynamic DNS through a 3rd party component called inadyn.  Inadyn natively supports many different dynamic DNS providers, including custom providers.

More information on inadyn can be found here: https://github.com/troglobit/inadyn. More information on AWS Route53 can be found here: https://aws.amazon.com/route53/.  More information on Ubiquiti UniFi gateways can be found here: https://ui.com

## Who should use this

If you already host or are planning to host your DNS records with AWS Route53, and you would like to have dynamic DNS support via your UniFi gateway's builtin functionality, this project may be for you.

If you are simply looking for a dynamic DNS solution for your domain, there are lots of other solutions which may be more appropriate.  You are likely better off registering your domain, and/or hosting your DNS records with a provider that is natively supported by your UniFi gateway.

AWS is not a free service, nor is it simple. If you do not have experience related to managing AWS accounts, including managing cost and security you should not use AWS. You will incur unexpected bills, and you will likely get hacked and also incur unexpected bills. AWS is not a toy, and is not designed for hobbyists, students, and home lab enthusiasts, and personal projects (although it can be used for these purposes with proper training, research and experience). There are less expensive and more simple DNS hosting solutions available for the typical home or small business network.

## How it works

The inadyn client runs in the background on your UniFi gateway. When your public ip changes, the inadyn client will send a request to a url with your new public ip address. This project deploys a AWS Lambda function that will receive the client request, and the lambda will update the corresponding AWS Route53 record. The Lambda is directly callable from a Lambda Function Url endpoint that is assigned and managed by AWS. More information on Lambda Function Urls is available here: https://aws.amazon.com/blogs/aws/announcing-aws-lambda-function-urls-built-in-https-endpoints-for-single-function-microservices/

## What does it cost?

The cost should be minimal, and will likely fall within the free allocation of resources included in with the services. Even in the situation where your public ip address is changing near constantly the costs should be at most a few US pennies per month (if that).  However you will be billed for a few different AWS resource categories.  Specifically you will be charged EC2 data transfer costs, Route53 API requests, Lambda compute costs, Lambda API request costs, and Cloudwatch logging and metrics costs.

You will also be billed for Route53 hosted zones costs, and DNS query costs (however those costs are not part of this project, you are charged for them because you have chosen to use Route53 as a DNS zone hosting provider already).

You should refer to the Lambda, Route53, EC2 data transfer, and Cloudwatch pricing information available from https://aws.amazon.com/lambda/pricing/ and https://aws.amazon.com/route53/pricing/ and https://aws.amazon.com/ec2/pricing/on-demand/ and https://aws.amazon.com/cloudwatch/pricing/ for current and up to date information.

## Security considerations

The Lambda will have access to change resource records in a single hosted zone. The lambda is exposed to the public global internet via a Lambda Function Url. Anyone who knows this url, would be able to call it with the appropriate credentials, and your Lambda function will update your DNS record.  The Lambda Function Url, only responds on port 443 via the HTTPS protocol.  It does not respond on port 80 to insecure HTTP requests, nor will attempt to redirect the caller to HTTPS on port 443.

The Function Url is a randomized and unpredictable subdomain under the sole control of Amazon AWS. It will be unique to your installation, and there is no way to guess it.  You should be able to keep this url safe from abuse by simply not sharing it with anyone.

The Lambda function also requires a username and password combination which you can control and change at anytime. The username and password is provided using standard HTTP Basic Authentication.  While this method is simple, and not a robust security solution, in general it's use is considered acceptable for simple scenarios when combined with mandatory SSL/TLS.  While there are far more secure methods to protect a Url endpoint, we are limited by the options which the dynamic DNS client (inadyn) supports.

An adversary can find your unique Function Url, and your username and password combination if they have appropriate access to your UniFi gateway, and or your AWS account. I am comfortable with my security posture and ability to protect these resources. I have also considered the implications were any of this information, or credentials were to be leaked or obtained by a non trusted entity who intended me harm.  My need for dynamic DNS and my specific use cases are not mission critical, nor would it be a catastrophe were an attacker be able to gain control.

While I would prefer more security options to protect the Lambda endpoint, I am satisfied with the security mechanisms used here as it pertains to my needs and situation. You should evaluate for yourself and seek a different solution if you feel otherwise.

## Deployment and Getting Started

At a high level you need to deploy the required resources to your AWS account. This includes the Lambda function, and an IAM role for the Lambda function to assume. I have set this project up to deploy using Terraform. However you may use any deployment method of your choice including doing everything manually in the AWS console.

The following deployment steps assume you have already created the Route53 hosted zone that contains the record you wish to dynamically update.

### Terraform Deployment (recommended)

#### Step 1:  Clone this repository.

#### Step 2: Obtain the HostedZoneID

The HostedZoneID is the random value that AWS assigns to your Route53 hosted zone when you created it in AWS. You can obtain this in the AWS Route53 management console. Or if you have the AWS cli installed, you can run the following command in your terminal `aws route53 list-hosted-zones`

If you use the aws console to obtain this Id, then it will be shown in a format that looks like `XXXXXXXXX`.  If you use the AWS cli to get the Id, it will be shown in a format that looks like `/hostedzone/XXXXXXXXX`. When supplying the hostedZoneId in Step 3 below, the format you should use is `XXXXXXXXX` and you should omit the `/hostedzone/` part of the Id.

#### Step 3: Set terraform variables.

Create a a terraform.tfvars file in the root of your cloned repository that contains the following information. Do not check this file into source control (it is ignored by default)

```HCL
# Choose a region close to you
region = "us-east-1"

# These are the basic auth credentials the lambda function uses to authenticate the request. They will need to be added to your UniFi gateway when configuring custom dynamic DNS
authPass = "YourUserNameGoesHere"
authUser = "YourPasswordGoesHere"

# This is the hosted zone id of the hosted zone that contains the DNS record you wish to dynamically update
hostedZoneId = "ZXXXXXXXXXXXXV"

# These tags are entirely optional and can be modified to suit your needs and preferences. They will be added to all the resources which this module creates (a managed IAM policy, an IAM role, and a Lambda function)
common_tags = {
  "Name"               = "unifi-route53-ddns",
  "RootModuleSource"   = "https://github.com/estubbs/unifi-route53-ddns.git"
  "DeploymentType"     = "terraform"
  "TerraformStateFile" = "s3://estubbs-terraformstate/unifi-route53-ddns"
}

```
You may also set these variables using any alternative method of setting input variables supported by Terraform.

#### Step 4: Adjust the terraform backend configuration to your needs.

For my use case I have chosen to use an AWS S3 backend to host my terraform state. This repository is configured to use my personal setup, and it will not work for you. You must configure the project to use the Terraform backend configuration that suits your needs. You can also remove the entire backend section if you want to use a local file for your terraform state.

Edit the `main.tf` file and change the backend configuration to suit your preferences.

**YOU MUST EDIT OR REMOVE LINES 3 - 7 IN THE `main.tf` FILE**

```HCL
backend "s3" {
    bucket = "estubbs-terraformstate"
    region = "us-east-1"
    key    = "unifi-route53-ddns"
  }
```

#### Step 5: Plan and Deploy

You will need to be properly authenticated to your AWS account in order to deploy this. I take advantage of AWS SSO/IAM Identity Center. Because I am using a single AWS profile called `default` I can deploy this with no further changes or setup. However you might need to specify a different profile, or you may choose to provide your credentials to Terraform using alternative methods. This project should be compatible with any of the standard and common methods to do so. Consult the appropriate terraform and AWS documentation.

Open a terminal, and run `terraform init`, then run `terraform plan` inspect the output, and then run `terraform apply`.  If all goes well this project should be up and ready to go in a few moments.

#### Step 6: Take note of your Lambda Function Url.

After deploying run the `terraform output` command and take note of the `aws_lambda_function_url.function_url` variable. You will need this value when you configure your UniFi gateway for dynamic DNS.

Below is a sample of the output. Take note of the line line that begins with `"function_url" =`

```
➜  unifi-route53-ddns git:(main) ✗ terraform output
aws_lambda_function_url = {
  "authorization_type" = "NONE"
  "cors" = tolist([])
  "function_arn" = "arn:aws:lambda:us-east-1:XXXXXXX:function:unifi_route53_ddns"
  "function_name" = "unifi_route53_ddns"
  "function_url" = "https://XXXXXXXXXXXXX.lambda-url.us-east-1.on.aws/"
  "id" = "unifi_route53_ddns"
  "invoke_mode" = "BUFFERED"
  "qualifier" = ""
  "timeouts" = null /* object */
  "url_id" = "XXXXXXXXX"
}
```

#### Step 7: Configure your UniFi gateway for Custom Dynamic DNS.

1. Log in to your unifi controller, and navigate the to Network app.
2. Click the settings cog icon in the lower left.
3. Navigate to the Internet settings in the sidebar
4. Click on your Primary (WAN1) internet connection.
5. If you are on Auto Settings, you will need to switch to Manual.
6. Locate the Dynamic DNS setting, and click the '+' icon to 'Create New Dynamic DNS`
7. Use the *Service* drop down and select "custom"
8. Fill in the fields as outlined below.

> **Hostname:** `the.fully.qualified.domain.name.and.record.you.want.to.update`
ex: if the DNS A record you want to update is `test.subdomain.example.com` that is what you put in this field. *Do not include a trailing '.'*

> **Username:** the username you specified when deploying with terraform in step 3.

> **Password:** the password you specified when deploying with terraform in step 3.

> **Server:** the function_url from step 3, with some modifications. See below

As an example, assuming your function_url from step 3 is `https://xxxxxxxxxxxxxxx.lambda-url.us-east-1.on.aws/`  you need to change it to the following:
>

`xxxxxxxxxxxxxxx.lambda-url.us-east-1.on.aws/?host=%h&ip=%i`

The important part is to *REMOVE* the `https://` from the front of the url, and append `?host=%h&ip=%i` to the end. Make sure there is a `/` character between the end of the url domain and the beginning of the query string.

9. Click Save on the Dynamic DNS popup dialog box
10. Click the "Apply Changes" button at the bottom of the Internet Settings page.
11. Wait for your UniFi gateway to provision and apply these changes.
12. Test that changes to your public IP address are reflected in Route53. Depending your ISP, you may need to wait for them to change your IP address. In some situations you can force a change by rebooting your Gateway, or unplugging the network cable from it, or power cycling your modem, or your ONT.

### Deploying with the AWS console (not recommended)

I do not recommend this approach, because I think everyone should be using IaC tooling for managing AWS infrastructure, even for small projects. However this is a trivially simple AWS project and I can understand not everyone will want to setup, learn, and configure terraform.

1. Create an IAM role with the permissions outlined in the IAM Permission topic on this page.
2. Create a nodejs based empty lambda function. I have tested against `nodejs20.x` runtime.
3. Add a Function Url to your lambda, and assign it the role you created.
4. Add the following Environment variables to your lambda function: `authUser` and `authPass`
5. Configure your UniFi gateway with your Function url, and the same username/password combination you specified for the lambda.  Follow step 7 from the Terraform deployment method section.

## AWS IAM Permissions

I have not documented the exact minimally necessary permissions needed to DEPLOY this. Since dynamic DNS is typically used in home and small business environment, I assume you have admin or near admin level permissions to your AWS account.

The permissions needed for this project to RUN are as follows.  They are assigned to the role the lambda uses.

The trust policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```
The permission policy:
```json
{
    "Statement": [
        {
            "Action": "route53:ChangeResourceRecordSets",
            "Effect": "Allow",
            "Resource": "arn:aws:route53:::hostedzone/<YourHostedZoneID>"
        },
        {
            "Action": "route53:ListHostedZonesByName",
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
```

## Troubleshooting

You can review the execution logs of your lambda function by looking at the cloudwatch logs and the lambda monitor dashboards.

You can also SSH into your UniFi gateway and observing the logs in `/var/log/messages`  You will see events related to dynamic dns containing the words `[inadyn]` which you can filter for.  You can use a command such as `cat /var/log/messages | grep inadyn` or `tail -f /var/log/messages | grep inadyn` to easily filter for the relevant information and or watch the log in realtime.

You can also look at the inadyn configuration file located at `/run/ddns-<something>-inadyn.conf`

You can also trigger inadyn manually and observe its behavior in the foreground by running the following command: `/usr/sbin/inadyn -n -s -C -f /run/ddns-<something>-inadyn.conf -1 -l debug --foreground`

Make sure to replace the `<something>` part in the above 2 commands as appropriate to the name of your inadyn.conf file which will vary depending on your specific internet connection.

## Contributing and future development

I will be the first to admit my Javascript programming knowledge is not up to date with the most recent techniques. Javascript is not my language of choice, however it provides good lightweight integration with AWS Lambda, and can be deployed without a build process. Because the Lambda runtime for Javascript includes all the necessary dependencies for this application, the lambda function package only needs to contain a single file.  I would welcome improvements to this code, especially in regards to error handling, and modern JS styles and techniques.  I would also welcome refactoring to improve the local development experience, and testing.

I am also not an expert terraform user. Most of my experience with similar tooling is with Cloudformation and CDK. I would welcome improvements to the terraform part of this project to make it easier to deploy and manage. The current setup suits my needs.

Documentation improvements are always welcome to any project. I would especially like to expand the documentation to include steps for manual deployment.

In all cases, feel free to send pull requests and/or create github issues.

## Support

Neither Ubiquiti, Amazon, nor Hashicorp can or will support you with this project in any way. I have no affiliation with them and cannot represent them. You might find help in general about dynamic DNS from the inadyn project located here: https://github.com/troglobit/inadyn but I am not affiliated with that project, nor are they with mine.

I have found useful guidance and information from the following sources, and I would like to thank all the contributors to these pages.

- https://github.com/troglobit/inadyn
- https://github.com/willswire/unifi-ddns
- https://community.ui.com/questions/How-to-Guide-to-Unifi-Gateway-DDNS-Dynamic-DNS-Services/6733acd9-61b3-4eba-80c1-d45df912e698

You may also find useful general guidance from the r/aws and r/ubiquiti communities on reddit. I hang out there also.

If you have questions or need help I will do my best but make no guarantees.  Generally I am unwilling to help with general AWS troubleshooting or guidance. This project is intended to be used by those who have made a conscious and well informed choice to host dns with Route53 and have the necessary experience and knowledge to control their account security and costs.
