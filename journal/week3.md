# Week 3 — Decentralized Authentication


# 1 Provision via ClickOps a Amazon Cognito User Pool

![1](https://user-images.githubusercontent.com/100797221/223719033-64a8d619-1510-4080-9d08-adeb8364c369.png)

It was done during live session and I remake it because of some wrong setup issues.


# 2 Install and configure Amplify client-side library for Amazon Congito

**Install AWS Amplify**
```
npm i aws-amplify --save

```
**Provision Cognito User Group**

Using the AWS Console we'll create a Cognito User Group

**Configure Amplify**

We need to hook up our cognito pool to our code in the <code>App.js</code>

```
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_AWS_PROJECT_REGION,
  "aws_cognito_identity_pool_id": process.env.REACT_APP_AWS_COGNITO_IDENTITY_POOL_ID,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});

```

**added Auto installation for AWS Amplify**

Paste this linees in <code>.gitpod.yml</code>:

```
- name: Install AWS Amplify
    command: cd frontend-react-js && npm i aws-amplify --save
```



