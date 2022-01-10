//
//  NetworkMonitor.swift v.0.2.1
//  shAre
//
//  Created by Eric PAJOT on 31.03.20.
//  Copyright © 2020 Eric PAJOT. All rights reserved.
//

import Foundation
import Network

/**
 NetworkMonitor.shared usage in a ViewController:

 1. get the current state when you need it

     print(NetworkMonitor.shared.connected ? "is connected" : "is disconnected"

 2. add a handler to get a notification when the connectivity changed

     NetworkMonitor.shared.handler = { isConnected in
         print(isConnected ? "is connected" : "is disconnected")
     }

 3. if the callback references the view controller's self, it must declare [weak self]
    to avoid memory retention cycles

     NetworkMonitor.shared.handler = { [weak self] isConnected in
         DispatchQueue.main.async {
             self?.connectedLabel.text = isConnected ? "connected" : "disconnected"
         }
     }

 4. ViewController can define the function activateNetworkStatus similar to this

     private func activateNetworkStatus() {
         NetworkMonitor.shared.handler = { [weak self] isConnected in
             DispatchQueue.main.async {
                 self?.connectedLabel.text = isConnected ? "connected" : "disconnected"
             }
         }
     }

 and call it from
 4.1 viewDidLoad
 4.2 from its func unwindToMyself(segue: UIStoryboardSegue) to reestablish the connectio

 */

class NetworkMonitor: NSObject {
    // MARK: public API

    /// client can access the singleton
    static var shared = NetworkMonitor()

    /// status, can be queried by a client
    private(set) var connected = false

    /// handler, to be assigned by a client
    var handler: ((Bool) -> Void)? {
        didSet {
            printClassAndFunc(info: "\(oldValue as Any), \(handler as Any) connected= \(connected)")
            handler?(connected) // report connection status when client connects
        }
    }

    // MARK: private implementation

    private var monitor = NWPathMonitor()

    private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            self.connected = (path.status == .satisfied)
            self.handler?(self.connected) // report connection status when it changes
            self.printClassAndFunc(info: "connected= \(self.connected)")
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }

    private func stopMonitoring() {
        monitor.cancel()
        monitor.pathUpdateHandler = nil
    }

    private override init() {
        super.init()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }
}


