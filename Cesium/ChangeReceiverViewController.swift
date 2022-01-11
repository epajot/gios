//
//  ChangeReceiverViewController.swift
//  Cesium
//
//  Created by Jonathan Foucher on 03/06/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import Foundation
import UIKit
import Network

class ChangeUserTableViewCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var endResults: UILabel!
    
    
    var profile: Profile?
}

class LoadingViewCell: UITableViewCell {
    @IBOutlet weak var activity: UIActivityIndicatorView!
}

class ChangeReceiverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    let networkStatusView = getNetworkStatusView()
    @IBOutlet weak var close: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var search: UITextField!
    @IBOutlet weak var topBarHeight: NSLayoutConstraint!
    var request: Request?
    var profiles: [Profile?] = []
    var page: Int = 0
    var end: Bool = true
    var loading: Bool = false
    weak var profileSelectedDelegate: ReceiverChangedDelegate?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(networkStatusView)
        activateNetworkStatusView(statusView: networkStatusView)
        self.close.text = "close_label".localized()
        self.tableView.rowHeight = 64.0
//        self.search.becomeFirstResponder()
        hideKeyboardWhenTappedAround()
        self.search.attributedPlaceholder = NSAttributedString(
            string: "search_placeholder".localized(),
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        self.search.layer.borderWidth = 1
        self.search.layer.backgroundColor = UIColor(named: "EP_Blue")?.cgColor //UIColor.white.cgColor
        self.search.layer.borderColor = UIColor(named: "EP_Blue")?.cgColor //UIColor.white.cgColor
        self.search.layer.cornerRadius = 6
        
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            print("found")
            self.topBarHeight.constant = navigationController.navigationBar.frame.height
            self.view.layoutIfNeeded()
        }
        
        // get all members
        //https://g1.jfoucher.com/wot/lookup/jon
        //https://g1.data.duniter.fr/user,page,group/profile,record/_search?q=title:jonathan
        // https://g1.data.duniter.fr/user,page,group/profile,record/_search?q=title:*jo*&size=100&from=0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.shared.appDidBecomeActiveCallback = appDidBecomeActive
    }
    
    func appDidBecomeActive() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! ChangeUserTableViewCell
        print("selected", indexPath)
        if let prof = cell.profile {
            self.profileSelectedDelegate?.receiverChanged(receiver: prof)
            self.dismiss(animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.profiles.count + 1;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.count > 0 && self.profiles.count > indexPath.row) {
            if let prof = self.profiles[indexPath.row] {
                let cell = tableView.dequeueReusableCell(withIdentifier: "UserPrototypeCell", for: indexPath) as! ChangeUserTableViewCell
                cell.profile = prof
                cell.name.text = prof.getName()
                prof.getAvatar(imageView: cell.avatar)
                if let time = prof.time {
                    let date = Date(timeIntervalSince1970: Double(time))
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = NSLocale.current
                    dateFormatter.dateFormat = "dd/MM/YYYY HH:mm:ss"
                    cell.date?.text = dateFormatter.string(from: date)
                    cell.avatar.layer.cornerRadius = cell.avatar.frame.height / 2
                }
                return cell
            }
        }
        
        print(self.loading, self.end)
        
        if (indexPath.row == self.profiles.count && self.end == false) {
            self.page += 1
            print("loading page", self.page)
            if let searchText = self.search.text {
                self.loadPage(search: searchText)
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserLoadingCell", for: indexPath) as! LoadingViewCell
            cell.activity.startAnimating()
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EndCell", for: indexPath) as! ChangeUserTableViewCell
        cell.endResults.text = "end_results".localized()
        return cell
    }
    
    @IBAction func searchChanged(_ sender: UITextField) {
        print("change", sender.text as Any)
        self.page = 0
        self.end = false
        self.profiles = []
        self.loading = false
        if let req = self.request {
            req.cancel()
        }
        if let searchText = self.search.text {
            print("change", searchText)
            self.loadPage(search: searchText)
        }
    }
    
//    func openQRCodeReader() {
//        DispatchQueue.main.async {
//            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//
//            let QRCodeView = storyBoard.instantiateViewController(withIdentifier: "QRCodeView") as! QRCodeViewController
//
//            QRCodeView.isModalInPopover = true
//            QRCodeView.profileSelectedDelegate = self
//
//            self.present(QRCodeView, animated: true, completion: nil)
//        }
//    }
    
    @IBAction func backBtnTapped(_ sender: Any) {
        vibrateLight()
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadPage(search: String) {
        let count = 20
        let url = String(format:"%@/user,page,group/profile,record/_search?q=title:%@&size=%d&from=%d&sort=_score:desc", "default_data_host".localized(), search, count, self.page * count).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        print(url)
        self.loading = true
        self.request = Request(url: url)
        self.request?.jsonDecodeWithCallback(type: ProfileSearchResponse.self, callback: { error, response in
            self.request = nil

            self.loading = false
            if let hits = response?.hits {
                if let total = hits.total {
                    if (total > 0 && hits.hits.count > 0) {
                        let newProfiles = hits.hits.map { (p) -> Profile? in
                            if let prof = p._source {
                                return prof
                            }
                            return nil
                            }.filter({ (p) -> Bool in
                                return p != nil
                            })
        
                        self.profiles.append(contentsOf: newProfiles)
                        print("total", total)
                        self.end = false
                        
                    } else if (hits.hits.count == 0) {
                        self.end = true
                    }
                }
            }
            DispatchQueue.main.async { self.tableView?.reloadData() }
        })
    }
    
    @IBAction func cancel(_ sender: Any) {
        vibrateLight()
        self.dismiss(animated: true, completion: nil)
    }
}

extension ChangeReceiverViewController: ReceiverChangedDelegate {
    func receiverChanged(receiver: Profile) {
        self.profileSelectedDelegate?.receiverChanged(receiver: receiver)
        self.dismiss(animated: true, completion: nil)
    }
}
