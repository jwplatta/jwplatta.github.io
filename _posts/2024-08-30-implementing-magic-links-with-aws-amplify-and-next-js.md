---
layout: post
title: "Implementing Magic Links with AWS Amplify and Next.js"
date: 2024-08-30 22:24 -0500
categories: [web-development]
tags: [javascriot, aws, nextjs, authentication]
math: true
toc: true
img_path: /assets/img/posts/
---
## Motivation

I went on a little adventure recently while working on a prototype Next.js app. I needed to implement magic links for authentication. My team wanted to use magic links in our prototype because it reduces friction for users trying out our app; no one wants or needs another password. But implementing the links turned out to be a slog through the AWS documentation wilderness. The following captures the bits and pieces I had to pull together to make the solution work.

AWS Amplify makes setting up a lot of the standard backend resources an application needs very easy[^1]. However, it doesn't support magic links out of the box. So I needed to put together a custom authentication flow that uses DynamoDB, Cognito, and Lambda functions.

So here's a summary of the simple magic link strategy I implemented:
1. Create a unique token when the user submits the login form
2. Store this token in a DynamoDB table
3. Email the magic link to the user
4. When the user clicks the link, initiate a custom authentication flow to verify the token
5. If valid, authenticate the user and redirect them into the app, otherwise redirect them back to the login

## Creating and Sending the Link

In order to handle sending the magic link to users, I defined Lambda function in the Amplify backend resources. This function creates the unique token and stores it in a DynamoDB table. It the sends the email with the magic link. In order minimize vulnerabilities, I allowed a user to have only one valid link at a time and the links expire after a short period of time.

```javascript
// /amplify/functions/send-magic-link/handler.ts
import nodemailer from 'nodemailer';
import type { Schema } from "../../data/resource";
import { DynamoDBClient, GetItemCommand, PutItemCommand, DeleteItemCommand } from '@aws-sdk/client-dynamodb';
import { v4 as uuidv4 } from 'uuid';

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });

export const handler: Schema["sendMagicLink"]["functionHandler"] = async (event) => {
  const recipientEmail = event.arguments.email;
  if (!recipientEmail) {
    return false;
  }

  const getParams = {
    'TableName': process.env.TABLE_NAME,
    'Key': {
      'email': {
        'S': recipientEmail
      }
    }
  };

  const getCommand = new GetItemCommand(getParams);
  const magicLink = await ddbClient.send(getCommand);

  if (magicLink.Item) {
    const deleteParams = {
      'TableName': process.env.TABLE_NAME,
      'Key': {
        'email': {
          'S': recipientEmail
        }
      }
    };

    const deleteCommand = new DeleteItemCommand(deleteParams);
    await ddbClient.send(deleteCommand);
  }

  const newToken = uuidv4();
  const putParams = {
    'TableName': process.env.TABLE_NAME,
    'Item': {
      'email': {
        'S': recipientEmail
      },
      'expirationDatetime': {
        'S': new Date(Date.now() + 15 * 60000).toISOString()
      },
      'token': {
        'S': newToken
      },
    }
  };

  const putCommand = new PutItemCommand(putParams);
  const newTokenItem = await ddbClient.send(putCommand);
  const loginLink = `"${process.env.HOST}/verify-magic-link?code=${encodeURIComponent(newToken)}&email=${encodeURIComponent(recipientEmail)}"`;
  const transporter = nodemailer.createTransport({
    service: process.env.EMAIL_SMTP_SERVICE,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD,
    },
  });

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: recipientEmail,
    subject: 'Login',
    html: `
    <p>Please use the link below to login:</p>
    <a href=${loginLink}>
      Login
    </a>`,
  };

  try {
    const response = await transporter.sendMail(mailOptions);
    return true;
  } catch (error) {
    return false;
  }
}
```

To use this function in the front end, I followed AWS's recommendation of defining a custom query in the backend data resource for the Amplify app[^2]:

```javascript
import { generateClient } from "aws-amplify/api"

export default function Login() {
	// ...
	const handleSignIn = async (e: React.MouseEvent<HTMLButtonElement>) => {
		// ...
		const client = generateClient<Schema>();
		await client.queries.sendMagicLink({ email: email });
	}
	// ...
}
```

## Custom Authentication Flow

Next, to make the authentication work, I needed to define a custom authentication flow in AWS Cognito. This flow requires defining three custom triggers in the form of Lambda functions[^3].

First, the Define Auth Challenge is the entry point to the auth flow. It determines whether to send the user the authentication challenge or the authentication tokens.
```javascript
// /amplify/auth/define-auth-challenge/handler.ts
import type { Handler } from 'aws-lambda';

export const handler: Handler = async (event, context) => {
  const { request } = event;

  if (request.userNotFound) {
    event.response.issueTokens = false
    event.response.failAuthentication = true
  } else if (request.session && request.session.length === 0) {
    event.response.issueTokens = false;
    event.response.failAuthentication = false;
    event.response.challengeName = "CUSTOM_CHALLENGE";
  } else if (request.session && request.session.length === 1 && request.session[0].challengeResult) {
    event.response.issueTokens = true;
    event.response.failAuthentication = false;
    event.response.challengeName = "CUSTOM_CHALLENGE";
  } else {
    event.response.issueTokens = false
    event.response.failAuthentication = true
  }

  return event;
}
```

The Create Auth Challenge then looks up the stored token from the DynamoDB table in order to create the custom challenge for the user. However, if the token is expired, then it'll fail the authentication flow.
```javascript
// /amplify/auth/create-auth-challenge/handler.ts
import type { Handler } from 'aws-lambda';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });

export const handler: Handler = async (event) => {

  const email = event.request.userAttributes.email;
  if (!email) {
	return event;
  }

  const params = {
    'TableName': process.env.TABLE_NAME,
    'Key': {
      'email': {
        'S': email
      }
    }
  };

  const command = new GetItemCommand(params);
  const result = await ddbClient.send(command);
  const token = result.Item?.token.S;
  const expirationDatetime = result.Item?.expirationDatetime.S;
  if (!token || !expirationDatetime) {
    return event;
  }

  const expiration = new Date(expirationDatetime);
  if (expiration < new Date()) {
    return event;
  }

  event.response.privateChallengeParameters = {
    challenge: token
  }

  return event;
}
```

Finally, the Verify Auth Challenge trigger checks the token retrieved in the Create Auth Challenge function against the token supplied by the user's magic link.
```javascript
// /amplify/auth/verify-auth-challenge/handler.ts
import type { Handler } from 'aws-lambda';
import { DynamoDBClient, DeleteItemCommand } from '@aws-sdk/client-dynamodb';

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });

export const handler: Handler = async (event, context) => {
  const { request } = event;
  const expected = event.request.privateChallengeParameters.challenge
  if (event.request.challengeAnswer === expected) {
    event.response.answerCorrect = true;

    const deleteParams = {
      'TableName': process.env.TABLE_NAME,
      'Key': {
        'email': {
          'S': event.request.userAttributes.email
        }
      }
    };

    const deleteCommand = new DeleteItemCommand(deleteParams);
    await ddbClient.send(deleteCommand);
  } else {
    event.response.answerCorrect = false;
  }

  return event;
}
```

Finally, to get the backend of the Amplify app to use this custom authentication flow, I needed to add these lambda functions as triggers when defining the backend authentication resource.
```javascript
// /amplify/auth/resource.ts
import { defineAuth } from "@aws-amplify/backend";
import { defineAuthChallenge } from "./define-auth-challenge/resource";
import { createAuthChallenge } from "./create-auth-challenge/resource";
import { verifyAuthChallengeResponse } from "./verify-auth-challenge/resource";
import { preSignUp } from "./pre-sign-up/resource";

export const auth = defineAuth({
  loginWith: {
    email: true
  },
  userAttributes: {
    givenName: {
      mutable: true,
      required: true
    },
    familyName: {
      mutable: true,
      required: true
    }
  },
  triggers: {
    preSignUp,
    createAuthChallenge,
    defineAuthChallenge,
    verifyAuthChallengeResponse
  }
});

```

Overall, it was an interesting little project that required piecing together various AWS services and documentation. It provided a good opportunity to dive deeper into Amplify's customization options and created a smoother user experience for my team's prototype app.

## References
[^1]: https://docs.amplify.aws/nextjs/build-a-backend/auth/set-up-auth/
[^2]: https://docs.amplify.aws/react/build-a-backend/functions/set-up-function/
[^3]: https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-challenge.html