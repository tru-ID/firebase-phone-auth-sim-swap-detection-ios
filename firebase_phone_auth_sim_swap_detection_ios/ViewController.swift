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
    
    
    @IBAction func verify(_ sender: Any) {
        if let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty {
            controls(enabled: false)
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
                    self.controls(enabled: true)
                }
            }
        }
    }
    
    func truIDSIMCheckVerification(phoneNumber: String, completionHandler: @escaping (Bool, Error?) -> Void) {
        let session = URLSession.shared
        let url = URL(string: "https://rotten-horse-35.loca.lt/sim-check")!
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
    
    func executeFirebasePhoneVerification(phoneNumber: String) {
        if let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty {
            Auth.auth().languageCode = "en"
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] (verificationID, error) in
                if let error = error {
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    self?.present(alertController, animated: true, completion: nil)
                    return
                }
                
                //Save in case the app is terminated.
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
            }
            
        }
    }
    
    private func controls(enabled: Bool) {

        if enabled {
            busyActivityIndicator.stopAnimating()
        } else {
            busyActivityIndicator.startAnimating()
        }

        phoneNumberTextField.isEnabled = enabled
        verifyButton.isEnabled = enabled
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
}

