# SIM Swap Detection with iOS Firebase Phone Authentication

In this tutorial, we will take you through how to add SIM swap detection to an iOS application authenticated with Firebase Phone Auth. You will use [**tru.ID SimCheck**](https://developer.tru.id/docs/sim-check) to verify if the SIM Card associated with the mobile phone number was changed recently in order to detect any attempted [SIM swap fraud](https://en.wikipedia.org/wiki/SIM_swap_scam). 
### The **tru.ID** SIMCheck API provides information on when a SIM card associated with a mobile phone number was last changed. This provides an extra layer of security in your application login flows, and can be used to detect attempted SIM swap fraud. It can be used to augment existing 2FA or anti-fraud workflows.

### If you'd prefer to go directly to the completed code, it's in [firebase-phone-auth-sim-swap-detection-ios](https://github.com/tru-ID/firebase-phone-auth-sim-swap-detection-ios) Github repository.

## Before you begin
You will need to:

- Download  [Xcode 12](https://developer.apple.com/xcode/)
- Register for a developer account at [Apple Developer Portal](https://developer.apple.com/account/) if you do not have one already
- Have an iPhone or an iPad with a SIM card 
- Have [node.js](https://nodejs.org/en/download/) installed for the **tru.ID** CLI

## Set-up the tru.ID CLI and Run a Development Server
First, create a [tru.ID Account](https://tru.id) by clicking [Get Started](https://developer.tru.id/console) which will take you to the Console.
Next, you need to install the [**tru.ID** CLI](https://developer.tru.id/). This will help you create a development server up and running, which the sample app will be using to accomplish the necessary steps for SIMCheck set it up using the command provided in the [tru.ID console](https://developer.tru.id/console):
```bash
$ npm install -g @tru_id/cli

```
Input your **tru.ID** Default Workspace Credentials as displayed at your [tru.ID console](https://developer.tru.id/console) to set up the tru.ID CLI:

```bash
$ tru setup:credentials {client_id} {client_secret} {data_residency}
```

Install the development server plugin:

```bash
$ tru plugins:install @tru_id/cli-plugin-dev-server@canary
```

Create a new **tru.ID** project:

```bash
$ tru projects:create firebaseAuthSimIos
```
This saves a tru.json **tru.ID** project configuration to ./firebaseauthsimios/tru.json
Run the development server by pointing it to the newly created project directory and configuration. This will also open up a localtunnel to your development server, making it publicly accessible to the Internet, so that your mobile phone can access it when only connected to mobile data.
```bash
$ tru server --project-dir ./firebaseauthsimios
```

Take a note of the local tunnel URL, which will be needed for configuring the sample project. The URL is in the format https://{subdomain}.loca.lt. This is the public accessible URL to your local development server. The development server is now ready and waiting to accept calls from the app. Now, we can continue with creating our new iOS project.

## Create a New iOS Project

With the **tru.ID** account created and the development server up and running, we can make a start with the application. You can skip this step if you already have an iOS project. Otherwise;

⋅⋅* Launch your Xcode
⋅⋅* File -> New -> Project
⋅⋅* In the "Choose a template for your new project" modal, select App and click Next
⋅⋅* Set "sim-card-auth-ios" as the Product Name, however, you can use whatever the name of your project is
⋅⋅* Select your Team, and make sure to assign an organization identifier using a reverse domain notation
⋅⋅* Keep it simple, and use a **Storyboard**, **UIKit App Delegate** and **Swift** as the development language
⋅⋅* Uncheck **Use Code Data** if it is checked, and click Next
⋅⋅* Select the folder you want to store your project in and click Next
As you see, it is a pretty simple project with a single ViewControlller. At this point, you do not need to worry about the `AppDelegate` or `SceneDelegate`. This is enough to demonstrate SimCheck.

If you already have Xcode and have added your developer account (Xcode->Preferences->Accounts), Xcode takes care of generating necessary certificates and provisioning profiles in order to install the app on the device.

## Build the User Interface

## Create Firebase Project
Follow the instructions at the official Firebase documentation to [Add Firebase to your iOS project](https://firebase.google.com/docs/ios/setup#initialize_firebase_in_your_app)

After completing all 5 steps





