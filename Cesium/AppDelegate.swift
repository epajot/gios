//
//  AppDelegate.swift
//  Cesium
//
//  Created by Jonathan Foucher on 30/05/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import UIKit
import RudifaUtilPkg

let nodes = [
    "https://g1.presles.fr",
    "https://g1.duniter.org",
    "https://g1.jfoucher.com",
    "https://g1.data.adn.life",
    "https://g1.cgeek.fr",
    "https://g1.nordstrom.duniter.org",
]

var currentNode = nodes[0]

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var appDidBecomeActiveCallback: (() -> Void)?

    var g1PaymentRequested: G1URLPayment?

    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        printClassAndFunc("@-----")
        return true
    }

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // this code will be replaced by code for handling the incoming URL
        printClassAndFunc("@-----")
        let message = url.absoluteString.removingPercentEncoding
        let alertController = UIAlertController(title: "Incoming Message", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertController.addAction(okAction)

//      window?.rootViewController?.present(alertController, animated: true, completion: nil)

//        presentAlert(alertController)

        g1PaymentRequested = G1URLPayment(g1URLString: url.absoluteString)

        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        printClassAndFunc("@")
        appDidBecomeActiveCallback?()
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // this works, keep it
    private func presentAlert(_ alert: UIAlertController) {
        if var controller = window?.rootViewController {
            while controller.presentedViewController != nil {
                // rudifa: I suppose that this should not happen, so I assert it
                assert(controller != controller.presentedViewController)
                controller = controller.presentedViewController!
            }
            controller.present(alert, animated: true)
        } else {
            printClassAndFunc("*** window?.rootViewController == nil")
        }
    }
}

extension String {
    func localized(bundle _: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
    }
}
