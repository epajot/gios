//
//  NetworkStatusUtil.swift
//  GiOS
//
//  Created by Rudolf Farkas on 01.04.20.
//  Copyright © 2020 Eric PAJOT. All rights reserved.
//

import UIKit

/*

     // in ViewController
     let networkStatusView = getNetworkStatusView()
     view.addSubview(networkStatusView)

     // in @IBAction func unwindTo... (if any)
     activateNetworkStatusView(statusView: networkStatusView)

 */

func getNetworkStatusView() -> UIView {
    let exclamationView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.tintColor = UIColor.systemOrange
        if #available(iOS 13.0, *) {
            view.image = UIImage(systemName: "exclamationmark.triangle")
        } else {
            // Fallback on earlier versions
        }
        return view
    }()

    let networkLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemOrange
        label.backgroundColor = .clear // uncomment for visual debugging
        label.font = UIFont.preferredFont(forTextStyle: .body) // .systemFont(ofSize: 18)
        label.text = "No Network"
        label.textAlignment = .center
        label.sizeToFit()
        label.isHidden = false
        return label
    }()

    let horStack = UIStackView.horizontal(subviews: [exclamationView, networkLabel])
    horStack.distribution = .equalSpacing
    return horStack
}

extension UIViewController {
    /// MUST BE CALLED IN viewWillAppear (or in viewDidAppear) AND IN @IBAction func unwindTo... (IF ANY)
    func activateNetworkStatusView(statusView: UIView) {
        NSLayoutConstraint.activate([
            statusView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            statusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
        ])

        NetworkMonitor.shared.handler = { isConnected in
            DispatchQueue.main.async {
                statusView.isHidden = isConnected
            }
        }
    }
}
