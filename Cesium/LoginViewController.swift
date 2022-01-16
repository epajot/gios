//
//  LoginViewController.swift
//  Cesium
//
//  Created by Jonathan Foucher on 30/05/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import CryptoSwift
import Foundation
import LocalAuthentication
import Sodium
import UIKit

enum PublicKeyError: Error {
    case emptyFields
    case couldNotCalculate
}

struct KeyPair {
    var publicKey: Bytes
    var secretKey: Bytes
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var secret: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var publicKey: UILabel!
    @IBOutlet var keyImage: UIImageView!
    @IBOutlet var topbarHeight: NSLayoutConstraint!
    @IBOutlet var topBar: UIView!
    
    var sendingTransaction: Bool = false
    
    weak var loginDelegate: LoginDelegate?
    weak var loginFailedDelegate: LoginFailedDelegate?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.keyImage.image = nil
        self.publicKey.text = ""
        
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            print("found")
            self.topbarHeight.constant = navigationController.navigationBar.frame.height
            self.view.layoutIfNeeded()
        }
        
        if let p = self.parent {
            let name = NSStringFromClass(type(of: p))
            if name == "Cesium.FirstViewController" {
                self.topBar.removeFromSuperview()
            }
        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true,
                     completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 /* && UIScreen.main.bounds.height - 420 < keyboardSize.height */ {
                var val = CGFloat(100.0)
                if let frame = self.loginButton?.frame {
                    val = CGFloat(UIScreen.main.bounds.height - frame.origin.y) - frame.height - 10
                }
                self.view.frame.origin.y -= CGFloat(keyboardSize.height) - val
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let image = UIImage(named: "logo")
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 100, width: 150, height: 150)
        imageView.center.x = self.view.center.x
        // self.view.addSubview(imageView)
        let backItem = UIBarButtonItem()
        backItem.title = "logout_button_label".localized()
        backItem.tintColor = .white
        self.navigationItem.backBarButtonItem = backItem
        
        self.secret.borderStyle = UITextField.BorderStyle.roundedRect
        self.secret.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        self.secret.layer.borderColor = UIColor.white.cgColor
        self.secret.layer.borderWidth = 1
        self.secret.layer.cornerRadius = 6
//        self.secret.placeholder = "identifier_placeholder".localized()
        self.secret.attributedPlaceholder = NSAttributedString(
            string: "identifier_placeholder".localized(),
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        self.secret.addTarget(self, action: #selector(self.fieldEditingChanged), for: UIControl.Event.editingChanged)
        
        self.password.borderStyle = UITextField.BorderStyle.roundedRect
        self.password.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        self.password.layer.borderColor = UIColor.white.cgColor
        self.password.layer.borderWidth = 1
        self.password.layer.cornerRadius = 6
//        self.password.placeholder = "password_placeholder".localized()
        self.password.attributedPlaceholder = NSAttributedString(
            string: "password_placeholder".localized(),
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        self.password.addTarget(self, action: #selector(self.fieldEditingChanged), for: UIControl.Event.editingChanged)
        
        // sampleTextField.delegate = self
        // self.view.addSubview(self.secret)
        // self.view.addSubview(self.password)
        
        self.loginButton.layer.borderColor = UIColor.white.cgColor
        self.loginButton.layer.borderWidth = 1
        self.loginButton.layer.cornerRadius = 6
        self.loginButton.setTitle("login_button_label".localized(), for: .normal)
        self.loginButton.addTarget(self, action: #selector(self.buttonAction), for: UIControl.Event.touchUpInside)
       
        self.keyImage.tintColor = .darkGray
        
        let context = LAContext()
        var error: NSError?
        let username = UserDefaults.standard.string(forKey: "lastUser")
        print("username", username as Any)
        let profile = Profile.load()
        print("profile", profile as Any)
        if username != nil, context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error), profile == nil || self.sendingTransaction {
            let blurEffect = UIBlurEffect(style: .light)

            let blurView = UIVisualEffectView(effect: blurEffect)

            blurView.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(blurView)
            NSLayoutConstraint.activate([
                blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
                blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
            ])
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: String(format: "user_auth_prompt".localized(), username ?? "")) {
                [unowned self] success, _ in
                
                    DispatchQueue.main.async {
                        blurView.removeFromSuperview()
                        if success {
                            if let savedProfile = KeyChain.load(key: "profile") {
                                self.printClassAndFunc("@ ---- Loaded Profile from Keychain")
                                let decoder = JSONDecoder()
                                if let loadedProfile = try? decoder.decode(Profile.self, from: savedProfile) {
                                    self.loginDelegate?.login(profile: loadedProfile)
                                }
                            }
                        }
                    }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.secret {
            textField.resignFirstResponder()
            self.password.becomeFirstResponder()
        } else if textField == self.password {
            textField.resignFirstResponder()
            self.buttonAction()
        }
        return true
    }
    
    @objc func fieldEditingChanged(_ sender: Any) {
        do {
            let pk = try self.calculatePublicKey()
            self.publicKey.text = pk
            self.keyImage.image = UIImage(named: "key")
        } catch {
            self.error(message: "could not calculate public key", code: 0)
            self.keyImage.image = nil
            self.publicKey.text = ""
        }
    }
    
    func calculatePublicKey() throws -> String {
        let id: String = self.secret.text!
        let pass: String = self.password.text!
        guard let seed = try? self.calculateSeed(id: id, pass: pass) else {
            throw PublicKeyError.couldNotCalculate
        }
        
        let sodium = Sodium()
        let k = sodium.sign.keyPair(seed: seed)
        if let key = k {
            let encoded = Base58.base58FromBytes(key.publicKey)
            return encoded
        }
        throw PublicKeyError.couldNotCalculate
    }
    
    func calculateSeed(id: String, pass: String) throws -> Bytes {
        let password: [UInt8] = Array(pass.utf8)
        let salt: [UInt8] = Array(id.utf8)
        guard let seed = try? Scrypt(password: password, salt: salt, dkLen: 32, N: 4096, r: 16, p: 1).calculate() else {
            throw PublicKeyError.couldNotCalculate
        }
        return seed
    }
    
    @IBAction func buttonAction() {
        let id: String = self.secret.text!
        let pass: String = self.password.text!
        // We have the public key, make a request
        print(id, pass)
        guard let pubK = try? self.calculatePublicKey() else {
            print("no pubkey")
            return
        }
        
        Profile.getRequirements(publicKey: pubK, callback: { identity in
            if identity == nil {
                self.error(message: "no identity", code: 12)
            }
            
            Profile.getProfile(publicKey: pubK, identity: identity, callback: { profile in
                if var prof = profile {
                    // Keep the secret key in memory for the duration of the session
                    if let seed = try? self.calculateSeed(id: id, pass: pass) {
                        prof.kp = Base58.base58FromBytes(seed)
                    }
                    self.loginDelegate?.login(profile: prof)
                }
                DispatchQueue.main.async {
                    self.password.text = ""
                    self.secret.text = ""
                    self.publicKey.text = ""
                    self.keyImage.image = nil
                }
            })
        })
        // TODO: this checks if the user is in the API, but they could be only on the nodes
        // Should we let them in even if the api is not aware ?
        // https://g1.nordstrom.duniter.org/wot/requirements/9itUPU7CVJEHh5DszAYQvgdUvTDLUNkY6NngMfo3F18k
    }
    
    func error(message: String, code: Int) {
        if code == 12 {
            self.loginFailedDelegate?.loginFailed(error: message)
        }
    }
}
