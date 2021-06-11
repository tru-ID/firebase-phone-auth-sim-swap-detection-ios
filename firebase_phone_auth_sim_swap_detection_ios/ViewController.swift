//
//  ViewController.swift
//  firebase_phone_auth_sim_swap_detection_ios
//
//  Created by Didem Yakici on 27/04/2021.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    @IBOutlet weak var busyActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var verifyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func verify(_ sender: Any) {
        
        if var phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty {
            phoneNumber = phoneNumber.replacingOccurrences(of: "\\s*", with: "", options: [.regularExpression])
            controls(enabled: false)
            truIDSIMCheckVerification(phoneNumber: phoneNumber) { [weak self] result, error in
                DispatchQueue.main.async {
                    
                    if let err = error as? AppError {
                        self?.displayAlert(title: "Error", message: "App Error: \(err.rawValue)")
                        return
                    }
                    
                    if result == true {
                        self?.executeFirebasePhoneVerification(phoneNumber: phoneNumber)
                    } else {
                        self?.displayAlert(title: "SIM Change Detected", message: "SIM changed too recently. Please contact support.")
                    }
                    
                }
               
            }
    
        }
    }
    
    enum AppError: String, Error {
        case BadRequest
        case NoData
        case DecodingIssue
        case Other
    }

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
                        let noSimChange = json["no_sim_change"] as! Bool
                        completionHandler(noSimChange, nil)
                    }

                } catch {
                    completionHandler(false, AppError.DecodingIssue)
                    print("JSON error: \(error.localizedDescription)")
                }
            } else if (400...500) ~= httpResponse.statusCode {
                completionHandler(false, AppError.BadRequest)
                print("There is an error \(httpResponse)")
            } else {
                completionHandler(false, AppError.Other)
            }
        }

        task.resume()
    }
    
    func executeFirebasePhoneVerification(phoneNumber: String) {
            Auth.auth().languageCode = "en"
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] (verificationID, error) in
                if let error = error {
                    self?.displayAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                //Save in case the app is terminated.
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                
                self?.presentOTPTextEntry { (otpCode) in
                    let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
                    
                    if let code = otpCode, !code.isEmpty, let verificationID = verificationID {
                        
                        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
                        
                        Auth.auth().signIn(with: credential) { result, error in
                            if let error = error {
                                self?.displayAlert(title: "Error", message: error.localizedDescription)
                            } else {
                                //"Sign In Success"
                                self?.displayAlert(title: "Message", message: "Sign in Success")
                            }
                        }
                    } else {
                        self?.controls(enabled: true)
                    }
                }
            }
    }
    
    private func presentOTPTextEntry(completion: @escaping (String?) -> Void) {
        
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
        
        let onCancel: (UIAlertAction) -> Void = {_ in
            completion(nil)
        }
        
        OTPTextEntry.addAction(UIAlertAction(title: "Continue", style: .default, handler: onContinue))
        OTPTextEntry.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: onCancel))
        
        present(OTPTextEntry, animated: true, completion: nil)
    }
}

extension ViewController {
    private func controls(enabled: Bool) {
        if enabled {
            busyActivityIndicator.stopAnimating()
        } else {
            busyActivityIndicator.startAnimating()
        }
        phoneNumberTextField.isEnabled = enabled
        verifyButton.isEnabled = enabled
    }
    
    private func displayAlert(title: String, message: String) {
        let alertController = self.prepareAlert(title: title, message: message)
        self.present(alertController, animated: true, completion: nil)
        self.controls(enabled: true)
    }
    
    private func prepareAlert(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        return alertController
    }
}

