# SIM Swap Detection with iOS Firebase Phone Authentication

In this tutorial, we will take you through how to add SIM swap detection to an iOS application authenticated with Firebase Phone Auth. You will use **tru.ID** SIMCheck to verify if the SIM Card associated with the mobile phone number was changed recently in order to detect any attempted SIM swap fraud.

The **tru.ID** [SIMCheck API](https://developer.tru.id/docs/sim-check) indicates if a SIM card associated with a mobile phone number was changed within the last seven days. This provides an extra layer of security in your application login flows, and can be used to detect attempted [SIM swap fraud](https://tru.id/blog/what-is-sim-swap-prevent-account-takeover). It can be used to augment existing 2FA or anti-fraud workflows.

You can find the completed code in the [firebase-phone-auth-sim-swap-detection-ios](https://github.com/tru-ID/firebase-phone-auth-sim-swap-detection-ios) GitHub repository.

## Before you begin

You will need to:

- Download [Xcode 12.5](https://developer.apple.com/xcode/)
- Register for a developer account at [Apple Developer Portal](https://developer.apple.com/account/) if you do not have one already
- Have an iPhone or an iPad with a SIM card 
- Have [node.js](https://nodejs.org/en/download/) installed for the **tru.ID** CLI

## Set-up the **tru.ID** CLI and run a development server

First, create a [tru.ID Account](https://tru.id/signup). After signing up you'll land in the **tru.id** Console.

Next, you need to install the **tru.ID** CLI:

```
npm install -g @tru_id/cli
```

Input your **tru.ID** Default Workspace Credentials as displayed at your [tru.ID console](https://developer.tru.id/console) to set up the **tru.ID** CLI:

```
tru setup:credentials {client_id} {client_secret} {data_residency}
```

Install the [development server plugin](https://github.com/tru-ID/firebase-phone-auth-sim-swap-detection-ios/blob/tutorial/Tutorial.md):

```
tru plugins:install @tru_id/cli-plugin-dev-server
```

Create a new **tru.ID** project:

```
tru projects:create firebaseAuthSimIos
```

This saves a `tru.json` **tru.ID** project configuration to `./firebaseauthsimios/tru.json`.

Run the development server by pointing it to the newly created project directory and configuration. This will also open up a localtunnel to your development server, making it publicly accessible to the Internet, so that your mobile phone can access it when only connected to mobile data.

```
tru server --project-dir ./firebaseauthsimios
```

Take a note of the local tunnel URL, which will be needed for configuring the sample project. The URL is in the format `https://{subdomain}.loca.lt` This is the accessible public URL to your local development server. The development server is now ready and waiting to accept calls from the app. If your tunnel has ended, you can create a new one by repeating the final step.

Now, we can continue with creating our new iOS project.

## Create a new iOS project

With the **tru.ID** account created and the development server up and running, we can start developing an application. You can skip this step if you already have an iOS project. Otherwise;

* Launch your Xcode
* File -> New -> Project
* In the "Choose a template for your new project" modal, select **App** and click Next
* Set "firebase-phone-auth-sim-swap-detection" as the Product Name, however, you can use whatever the name of your project is
* Select your Team, and make sure to assign an organization identifier using a reverse domain notation
* Keep it simple, and use a **Storyboard**, **UIKit App Delegate** and **Swift** as the development language
* Uncheck **Use Code Data** if it is checked, and click Next
* Select the folder you want to store your project in and click Next

As you see, it is a very simple project with a single ViewControlller and this is enough to demonstrate SIMCheck and Firebase Phone Authentication.

If you already have Xcode and have added your developer account (Xcode->Preferences->Accounts), Xcode takes care of generating necessary certificates and provisioning profiles in order to install the app on the device.

## Add Firebase to your iOS project

Follow the instructions at the official Firebase documentation to [Add Firebase to your iOS project](https://firebase.google.com/docs/ios/setup). The offical instructions are well detailed and easy to follow; but the steps from the offical documentation are also provided below:

- Check the [Prerequisites](https://firebase.google.com/docs/ios/setup#prerequisites)
- Step 1: [Create a Firebase project](https://firebase.google.com/docs/ios/setup#create-firebase-project)
- Step 2: [Register your app with Firebase](https://firebase.google.com/docs/ios/setup#register-app)
- Step 3: [Add a Firebase configuration file](https://firebase.google.com/docs/ios/setup#add-config-file) 
(Drag and drop the downloaded GoogleService-Info.plist to your iOS Project. Make sure the config file name is not appended with additional characters, like (2).)
- Step 4: [Add Firebase SDKs to your app](https://firebase.google.com/docs/ios/setup#add-sdks) (Install [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#getting-started) as mentioned within the Prerequisites.)

    Create a Podfile if you don't already have one

    ```bash
    cd your-project-directory
    pod init
    ```

    Add the Firebase Auth pod to your application Podfile:

    ```
    target 'firebase-phone-auth-sim-swap-detection' do
        # Comment the next line if you don't want to use dynamic frameworks
        use_frameworks!

        # Pods for firebase-phone-auth-sim-swap-detection
        pod 'Firebase/Auth'
    end
    ```

    Install the pods:

    ```
    pod install
    ```

    Close Xcode. Open your `.xcworkspace` file to see the project in Xcode.

- Step 5: [Initialize Firebase in your app](https://firebase.google.com/docs/ios/setup#initialize-firebase)

    The final step is to add initialization code to your application.

    Import the Firebase module in your `UIApplicationDelegate`:

    ```swift
    import Firebase
    ```

    Configure a [FirebaseApp](https://firebase.google.com/docs/reference/ios/firebasecore/api/reference/Classes/FIRApp) shared instance, typically in your app's `application:didFinishLaunchingWithOptions:` method:

    ```swift
    // Use Firebase library to configure APIs
    FirebaseApp.configure()
    ```

After completing all 5 steps, you're set to build the User Interface within your iOS Project.

## Build the user interface

Navigate to the `Main.storyboard`. You need to add a few UI components to receive input from the user, and provide feedback:

- Add a `UILabel` to the View Controller's view as a title with a text "Verification"
- A `UILabel` with a text "Phone number" to indicate what the next text field is for
- A `UITextField` so that the user can enter their phone number
- A `UIButton` with the text "Verify" to trigger the SIMCheck request

All UI components are "Horizontally" aligned in the container using constraints. You should also define constraints to anchor the components as well. You can use Reset to Suggested Constraints within Resolve Auto Layout Issues.

The view layout should look like this:

![Screenshot1](Screenshot01.png)

Add a few configuration options for these UI components:

- Phone number `UITextField:` Select the text field, and on the **Attributes Inspector**, scroll to `Text Input Traits` and change the `Content Type` to `Telephone Number`. Also, change the `Keyboard Type` to `Phone Pad`.

Next, let's define Outlets in the ViewController so that you can control the UI state. Select `ViewController` in Xcode, and then by using the `⌥` select `Main.storyboard` file. Both `ViewController.swift` and `Main.storyboard` should be opened side by side.

Select the `UITextField` you inserted into the storyboard, and with `⌃` key pressed, drag a connection from the storyboard to the `ViewController.swift.` Xcode indicates possible places in the Editor where you can create an Outlet.

When you are happy, release the keys and mouse/trackpad. You will be prompted to enter a name for the variable; type `phoneNumberTextField`. This allows you to retrieve the phone number entered by the user.

You now have one last task to do related to the storyboard. Let's insert an action. When a user taps on the **Verify** button, you want the `ViewController` to know that the user wants to initiate the SIMCheck. So select the `Verify` button, and with your `⌃` key pressed drag a connection from the storyboard to the `ViewController.swift`. Xcode indicates possible places where you can create an `IBAction`. When you are happy, release the keys and mouse/trackpad. You will be prompted to enter a name for the method: type `verify` and Xcode will insert the method with a IBAction annotation.

![Screenshot2](Screenshot02.png)

## Add Firebase phone authentication

Now that you have your Firebase project set up and your User Interface built up, you can start with enabling Phone Number sign-in for your Firebase project.

Select "Authentication" within your Firebase project. Select "Phone", click the toggle to "enable" and select "Save".

You have already completed the **Before you begin** section and **Step 1** Enable Phone Number sign-in for your Firebase project, so proceed to enabling app verification:

### Enable app verification

There are two ways for Firebase Authentication to accomplish verifying that a phone number sign-in requests are coming from your app:

#### Silent APNs notifications

To setup [Silent APNs notifications](https://firebase.google.com/docs/auth/ios/phone-auth#start-receiving-silent-notifications) follow the Apple Developer guide for [Enable the Remote Notifications Capability](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app).

Please note that data-only cloud messaging only works on real devices where the app has background refresh enabled. If background refresh is disabled, or if using the Simulator, app verification uses the fallback reCAPTCHA flow allowing you to check if it is configured correctly.

To enable APNs notifications for use with Firebase Authentication:

1. In Xcode, [enable push notifications](https://help.apple.com/xcode/mac/current/#/devdfd3d04a1) for your project.
2. Upload your APNs authentication key to Firebase. If you don't already have an APNs authentication key, see [Configuring APNs with FCM](https://firebase.google.com/docs/cloud-messaging/ios/client#upload_your_apns_authentication_key).

    * Inside your project in the Firebase console, select the gear icon, select **Project Settings**, and then select the **Cloud Messaging** tab.
    * In **APNs authentication key** under **iOS app configuration**, click the **Upload** button.
    * Browse to the location where you saved your key, select it, and click **Open**. Add the key ID for the key (available in **Certificates, Identifiers & Profiles** in the [Apple Developer Member Center](https://developer.apple.com/membercenter/index.action)) and click **Upload**. If you already have an APNs certificate, you can upload the certificate instead.

#### reCAPTCHA verification

To enable the Firebase SDK to use [reCAPTCHA verification](https://firebase.google.com/docs/auth/ios/phone-auth#set-up-recaptcha-verification), add custom URL schemes to your Xcode project:

* Open your project configuration: double-click the project name in the left tree view. Select your app from the **TARGETS** section, then select the **Info** tab, and expand the **URL Types** section.
* Click the + button, and add a URL scheme for your reversed client ID. To find this value, open the `GoogleService-Info.plist` configuration file, and look for the `REVERSED_CLIENT_ID` key. Copy the value of that key, and paste it into the **URL Schemes** box on the configuration page. Leave the other fields blank.

### Send a verification code

With all the configuration set up we're in a position to write the code to [send a verification code to the user's phone](https://firebase.google.com/docs/auth/ios/phone-auth#send-a-verification-code-to-the-users-phone).

To do this, create a method for the Firebase Phone verification in `ViewController.swift` named `executeFirebasePhoneVerification` to be called when the `verify` button touched.

**TODO: code was updated to check the phone number value within `verify` and then call `executeFirebasePhoneVerification`, passing a phone number**

**TODO: I think we need some user feedback that something is happening. At least disable the textfield and button. Can we add a function to toggle this?**

```swift
import Firebase

@IBAction func verify(_ sender: Any) {
    if let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty {
        self.executeFirebasePhoneVerification(phoneNumber: phoneNumber)
    }
}

func executeFirebasePhoneVerification(phoneNumber: String) {
    Auth.auth().languageCode = "en"

    PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] (verificationID, error) in
        if let error = error {
        // An Alert is created to notify the User for errors.
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
                self?.dismiss(animated: true, completion: nil)
            }))
            self?.present(alertController, animated: true, completion: nil)
            return
        }

        UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
    }
}
```

The `verify` method in the above code gets the user's phone number from the phone number text field, checks the value and calls `executeFirebasePhoneVerification`.

Within `executeFirebasePhoneVerification` the auth language is set to English and `verifyPhoneNumber:UIDelegate:completion:` is called, passing to it the phone number.

When you call `verifyPhoneNumber:UIDelegate:completion:`, Firebase sends a silent push notification to your app, or issues a reCAPTCHA challenge to the user. After your app receives the notification or the user completes the reCAPTCHA challenge, Firebase sends an SMS message containing an authentication code to the specified phone number and passes a verification ID to your completion function. You will need both the verification code and the verification ID to sign in the user.

The call to `UserDefaults.standard.set` saves the verification ID so it can be restored when your app loads. By doing so, you can ensure that you still have a valid verification ID if your app is terminated before the user completes the sign-in flow (for example, while switching to the SMS app).

If the call to `verifyPhoneNumber:UIDelegate:completion:` succeeds you can prompt the user to type the verification code when they receive it via SMS message.

### Sign the user in

Add the following method to the `ViewController.swift` to prompt the user to enter their OTP code that has been sent via SMS:

```swift
private func presentOTPTextEntry(completion: @escaping (String) -> Void) {
    
    let OTPTextEntry = UIAlertController(
        title: "Sign in with Phone Auth",
        message: nil,
        preferredStyle: .alert
    )
    OTPTextEntry.addTextField { textfield in
        textfield.placeholder = "Enter OTP code."
        textfield.textContentType = .oneTimeCode
    }
    
    let onContinue: (UIAlertAction) -> Void = { _ in
        let text = OTPTextEntry.textFields!.first!.text!
        completion(text)
    }
    
    OTPTextEntry.addAction(UIAlertAction(title: "Continue", style: .default, handler: onContinue))
    OTPTextEntry.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    present(OTPTextEntry, animated: true, completion: nil)
}
```

Here, we dynamically build a UI with a `UITextField` for the OTP and buttons for "Continue" and "Cancel". Upon completion the value of the text field - the OTP - is returned.

Update the `executeFirebasePhoneVerification` method to call the `presentOTPTextEntry` function and sign the user in:

```swift
...

UserDefaults.standard.set(verificationID, forKey: "authVerificationID")

self?.presentOTPTextEntry { (otpCode) in
    let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
    
    if !otpCode.isEmpty, let verificationID = verificationID {
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otpCode)
        
        Auth.auth().signIn(with: credential) { result, error in
            guard error == nil else {
                let alertController = UIAlertController(title: "Error", message: "There is something wrong with the OTP", preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
                    self?.dismiss(animated: true, completion: nil)
                }))
                self?.present(alertController, animated: true, completion: nil)
                return
            }

            //"Sign In Success"
            let alertController = UIAlertController(title: "Message", message: "Sign in Success", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
                print("OK button pressed")
                self?.dismiss(animated: true, completion: nil)
            }))
            self?.present(alertController, animated: true, completion: nil)
        }
    }
}
```

After the user provides your app with the verification code from the SMS message, retrieve the stored `verificationID`.

Then, with the verfication code stored in the `otpCode` variable, sign the user in by creating a `FIRPhoneAuthCredential` object (assigned to the `credentials` variable) from the verification code and verification ID and passing that object to `signInWithCredential:completion:`.

``` swift
let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otpCode)

Auth.auth().signIn(with: credential) { result, error in

...
```

The user receives an Alert Notification either as "Sign in Success" when the OTP entered is valid or "There is something wrong with the OTP".

You have now completed the code for authenticating with Firebase.

**REVIEWED TO HERE**

## Adding SIM swap detection with SIMCheck

We're now ready to add SIM Swap detection to the application's workflow using SIMCheck before signing in to Firebase.

Create a method called `truIDSIMCheckVerification`:

```swift
func truIDSIMCheckVerification(phoneNumber: String, completionHandler: @escaping (Bool, Error?) -> Void) {
    let session = URLSession.shared
    let url = URL(string: "https://{subdomain}.loca.lt/sim-check")!
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let json = [ "phone_number": phoneNumber ]
    let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
    urlRequest.httpBody = jsonData
    
    let task = session.dataTask(with: urlRequest) { data, response, error in
        if error != nil {
            completionHandler(false, error)
            return
        }
        
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode == 200 {
            print(String(data: data!, encoding: .utf8)!)
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any]{
                    if let noSimChange = json["no_sim_change"] as? Bool {
                        
                        if noSimChange == true {
                            completionHandler(true, error)
                        } else {
                            completionHandler(false, error)
                        }
                    }
                }
                
            } catch {
                completionHandler(false, error)
                print("JSON error: \(error.localizedDescription)")
            }
        } else {
            completionHandler(false, error)
            print("There is an error \(httpResponse)")
        }
    }
    task.resume()
}
```

There's a lot going on here so let's break it down.

We first make an HTTP POST request to the `sim-check` endpoint (i.e. localtunnel URL + /sim-check). The url will look like the following: `https://{subdomain}.loca.lt/sim-check`. In a production environment you should use your own servers.

### Set up the request with `URLSession`

We create a `session` constant with the shared `URLSession` instance, and set up a `URL` instance that refers to the development server URL. Then, with that `url`, create an instance of `URLRequest` and assign it to the `urlRequest` variable. For the purposes of this tutorial, it is safe to force-unwrap. On the last line, assign 'POST' to the `httpMethod`.

```swift
let session = URLSession.shared
let url = URL(string: "https://{subdomain}.loca.lt/sim-check")!
var urlRequest = URLRequest(url: url)
urlRequest.httpMethod = "POST"
```

### Set up the request headers and body

The header below indicates that the request type is JSON.

```swift
urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
```

The request needs a body. In our case it’ll be a JSON object. We first create a simple dictionary with some values.

```swift
let json = [ "phone_number": phoneNumber ]
```

We then turn that dictionary into a `Data` object that uses the JSON format and assigns it to the `urlRequest`'s body.

```swift
let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
urlRequest.httpBody = jsonData
```

### Make the request with `URLSessionDataTask`

Next, we create a data task with the `dataTask(with:completionHandler:)` function of `URLSession`.

```swift
let task = session.dataTask(with: urlRequest) { data, response, error in
//...
}
```

The `dataTask(with:completionHandler:)` has two parameters: urlRequest (created earlier) and a completion handler which will be executed when the `urlRequest` completes (i.e. when a response has returned from the web server).

### Handle the SIMCheck API result

The closure also has three parameters:

- the response `Data` object: to check out what data we receive from the webserver (jsonData)
- a `URLResponse` object: gives more information about the request's response such as its encoding, length etc. 
- an `Error` object: if an error occured while making the request, if no error occured it will be simply `nil`.
 
If any errors occured, the HTTP responses is not a `200`, or there is a problem deserializing the response then call the `completionHandler` with `false` and the `error`.

If the HTTP response is a `200` then determine whether the SIM card has changed:

```swift
if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any]{
    if let noSimChange = json["no_sim_change"] as? Bool {
        
        if noSimChange == true {
            completionHandler(true, error)
        } else {
            completionHandler(false, error)
        }
    }
}
```

A failed SIMCheck results in `false` being returned. A passed SIMCheck results in `true` being returned.

The network request is executed by calling `task.resume()` and the completion handler is invoked when the network request completes or fails.

## Integrate `truIDSIMCheckVerification`

Finally, integrate the new `truIDSIMCheckVerification` method so it's executed before the `executeFirebasePhoneVerification` method within `verify` method.

```swift
@IBAction func verify(_ sender: Any) {
    if let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty {
        truIDSIMCheckVerification(phoneNumber: phoneNumber) { result, error in
            DispatchQueue.main.async {
                if result == true {
                    self.executeFirebasePhoneVerification(phoneNumber: phoneNumber)
                } else {
                    let alertController = UIAlertController(title: "SIM Change Detected", message: "SIM changed too recently. Please contact support.", preferredStyle: UIAlertController.Style.alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
                        print("OK button pressed")
                        //Shall we dismiss the Alert or leave it there?
                        self.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }
    }
}
```

If the user's SIM has changed recently, we display an Alert to the user. If the SIM hasn't changed, we perform the Firebase phone authentication.

UI updates need to be done on the main queue so are wrapped in `DispatchQueue.main.async{ ... }` which ensures that all updates to the UI will be safely executed without causing any issues.

That's it! You’ve successfully integrated **tru.ID** SIMCheck with swap detection with your iOS application and can securely sign-in with your Phone on Firebase. 

## Where next?

- The completed sample app can be found in the **tru.ID** [firebase-phone-auth-sim-swap-detection-ios)](https://github.com/tru-ID/firebase-phone-auth-sim-swap-detection-ios) GitHub repository.
- [SIMCheck API reference](https://developer.tru.id/docs/reference/api#tag/sim_check)
- [SIM Card Based Mobile Authentication with iOS tutorial](https://developer.tru.id/tutorials/ios-sim-card-mobile-auth)

## Troubleshooting

If you have any questions please [raise an issue](https://github.com/tru-ID/tru-sdk-ios/issues) on the GitHub repo.

### Could not build Objective-C module 'Firebase'

Close Xcode. Open the `..xcworkspace` file in Xcode.

Also see [this Stackoverlow question](https://stackoverflow.com/questions/48727206/firebase-cocoapods-error-message-could-not-build-objective-c-module-firebase/48728282).