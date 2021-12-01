//
//  FirstViewController.swift
//  Cesium
//
//  Created by Jonathan Foucher on 30/05/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import CryptoSwift
import Sodium
import UIKit

class FirstViewController: UINavigationController, UINavigationBarDelegate {
    var loggedOut: Bool = false

    var selectedProfile: Profile?
    var profile: Profile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkNode(num: 0, callback: {})
        
        if let profile = Profile.load() {
            printClassAndFunc("@ saved profile loaded")
            self.login(profile: profile)
        } else {
            printClassAndFunc("@ present LoginView")
            self.loadLoginView()
        }
    }
    
    func loadLoginView() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let loginView = storyBoard.instantiateViewController(withIdentifier: "LoginView") as! LoginViewController
        loginView.loginDelegate = self
        loginView.loginFailedDelegate = self
        self.pushViewController(loginView, animated: true)
    }
    
    func checkNode(num: Int, callback: @escaping () -> Void) {
        printClassAndFunc("@\(num), \(nodes.count)")
        let request = Request(url: nodes[num] + "/")
        request.jsonDecodeWithCallback(type: DuniterResponse.self) { error, _ in
            if error != nil {
                if num + 1 < nodes.count {
                    self.printClassAndFunc("@error, next node will be \(num + 1)")
                    self.checkNode(num: num + 1, callback: callback)
                } else {
                    self.errorAlert(title: "no_internet_title".localized(), message: "no_internet_message".localized())
                }
            } else {
                currentNode = nodes[num]
                self.printClassAndFunc("@success, node \(num) \(currentNode)")
                callback()
            }
        }
    }
    
    func errorAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
    }
    
    func handleLogin(profile: Profile) {
        if profile.kp != nil {
            let encoder = JSONEncoder()
            
            if let encoded = try? encoder.encode(profile) {
                _ = KeyChain.save(key: "profile", data: encoded)
                UserDefaults.standard.set(profile.getName(), forKey: "lastUser")
            }
        }
        
        DispatchQueue.main.async {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let profileView = storyBoard.instantiateViewController(withIdentifier: "ProfileView") as! ProfileViewController
            let backItem = UIBarButtonItem()
            backItem.title = "logout_button_label".localized()
            backItem.tintColor = .white
            backItem.action = #selector(self.logout)
            profileView.navigationItem.leftBarButtonItem = backItem
            
            var saving = profile
            saving.kp = nil
            saving.save()
            self.profile = profile
            profileView.changeUserDelegate = self
            profileView.profile = profile
            profileView.loginProfile = profile
            self.pushViewController(profileView, animated: true)
        }
    }
    
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        // Very ugly but works for now
        if navigationBar.backItem?.backBarButtonItem?.title == nil || navigationBar.backItem?.backBarButtonItem?.title == "logout_button_label".localized(), self.loggedOut == false {
            self.logout()
            return false
        }
        self.popViewController(animated: true)
        return true
    }
    
    @objc func logout() {
        print("logout")
        let alert = UIAlertController(title: "logout_confirm_prompt".localized(), message: "", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "confirm_label".localized(), style: .default, handler: { _ in
            self.loggedOut = true
            print("removing profile")
            
            if let pk = self.profile?.issuer {
                UserDefaults.standard.removeObject(forKey: "identity-" + pk)
            }
            
            Profile.remove()
            
            self.profile = nil
            print(self.viewControllers.count)
            if self.viewControllers.count > 1 {
                self.popViewController(animated: true)
            } else {
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let loginView = storyBoard.instantiateViewController(withIdentifier: "LoginView") as! LoginViewController
                loginView.loginDelegate = self
                loginView.loginFailedDelegate = self

                self.viewControllers.insert(loginView, at: 0)
                self.popViewController(animated: true)
                // self.setViewControllers(vc, animated: true)
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "cancel_label".localized(), style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
}

protocol ViewUserDelegate: AnyObject {
    func viewUser(profile: Profile)
}

extension FirstViewController: ViewUserDelegate {
    func viewUser(profile: Profile) {
        print("in ViewUserDelegate")
        DispatchQueue.main.async {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let profileView = storyBoard.instantiateViewController(withIdentifier: "ProfileView") as! ProfileViewController
            
            profileView.profile = profile
            profileView.loginProfile = self.profile
            profileView.changeUserDelegate = self
            self.pushViewController(profileView, animated: true)
        }
    }
}

protocol LoginDelegate: AnyObject {
    func login(profile: Profile)
}

protocol LoginFailedDelegate: AnyObject {
    func loginFailed(error: String)
}

extension FirstViewController: LoginDelegate {
    func login(profile: Profile) {
        print("in delegate 1")
        self.loggedOut = false
        self.handleLogin(profile: profile)
    }
}

extension FirstViewController: LoginFailedDelegate {
    func loginFailed(error: String) {
        print("This account does not exist, do you want to create it or try again?")
        // TODO: display modal with signup
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "account_does_not_exist_title".localized(),
                                                    message: "account_does_not_exist_message".localized(),
                                                    preferredStyle: .actionSheet)

            let cancelAction = UIAlertAction(title: "account_does_not_exist_cancel".localized(), style: .cancel, handler: {
                _ in
                print("Cancel pressed")
            })
            let saveAction = UIAlertAction(title: "account_does_not_exist_create".localized(), style: .default, handler: {
                _ in
                
                print("Save pressed.")
            })
            alertController.addAction(cancelAction)
            alertController.addAction(saveAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
