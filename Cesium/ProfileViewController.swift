//
//  ProfileViewController.swift
//  Cesium
//
//  Created by Jonathan Foucher on 30/05/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import CryptoSwift
import Foundation
import Sodium
import UIKit

struct TransactionSection: Comparable {
    var type: String
    var transactions: [ParsedTransaction]

    static func < (lhs: TransactionSection, rhs: TransactionSection) -> Bool {
        return lhs.type < rhs.type
    }

    static func == (lhs: TransactionSection, rhs: TransactionSection) -> Bool {
        return lhs.type == rhs.type
    }
}

class TransactionTableViewCell: UITableViewCell {
    @IBOutlet var name: UILabel!
    @IBOutlet var date: UILabel!
    @IBOutlet var amount: UIButton!
    @IBOutlet var avatar1: UIImageView!

    var profile: Profile?

    var transaction: ParsedTransaction?

    override func awakeFromNib() {
        super.awakeFromNib()

        avatar1.layer.borderWidth = 1
        avatar1.layer.masksToBounds = false
        avatar1.layer.borderColor = UIColor.clear.cgColor
        avatar1.layer.cornerRadius = avatar1.frame.width / 2
        avatar1.clipsToBounds = true
    }
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var changeUserDelegate: ViewUserDelegate?
    var displayingAvatar: Bool = true
    @IBOutlet var check: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var publicKey: UILabel!
    @IBOutlet var keyImage: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var createTransactionButton: UIButton!
    @IBOutlet var transactBtn: UIButton!
    @IBOutlet var balanceLoading: UIActivityIndicatorView!
    var loginProfile: Profile?

    var profile: Profile? {
        didSet {
            if let nav = navigationController as? FirstViewController {
                nav.selectedProfile = profile
            }
        }
    }

    var sections: [TransactionSection]?
    var currency: String = ""

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()

        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)

        // refreshControl.tintColor = UIColor.red

        return refreshControl
    }()

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        if let pubkey = profile?.issuer {
            getTransactions(pubKey: pubkey, callback: {
                DispatchQueue.main.async {
                    self.printClassAndFunc(info: "@----- Pubkey = \(pubkey)") // EP's Test
                    refreshControl.endRefreshing()
                }
            })
            profile?.getBalance(callback: { total in
                let str = String(format: "%@ %.2f %@", "balance_label".localized(), Double(total) / 100, Currency.formattedCurrency(currency: self.currency))

                DispatchQueue.main.async {
                    self.balance.text = str
                    self.profile?.balance = total
                    self.printClassAndFunc(info: "@----- Balance = \(str)") // EP's Test
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 64.0

        logClassAndFunc(info: "@ Enter")

        if let profile = profile {
            logClassAndFunc(info: "@ Profile")
            name.text = profile.getName()
            balance.text = "balance_label".localized()
            publicKey.text = profile.issuer

            avatar.layer.borderWidth = 1
            avatar.layer.masksToBounds = false
            avatar.layer.borderColor = UIColor.white.cgColor
            avatar.layer.cornerRadius = avatar.frame.width / 2
            avatar.clipsToBounds = true

            transactBtn.isHidden = true
            transactBtn.layer.borderWidth = 1
            transactBtn.layer.borderColor = UIColor.white.cgColor
            balanceLoading.color = .white
            balanceLoading.startAnimating()
            

            profile.getAvatar(imageView: avatar)

            // make key image white
            keyImage.tintColor = .white
            keyImage.image = UIImage(named: "key")?.withRenderingMode(.alwaysTemplate)

            // Make checkmark image white
            check.tintColor = .white
            check.image = UIImage(named: "check")?.withRenderingMode(.alwaysTemplate)

            // Add image to send button
            let imv = UIImage(named: "g1")?.withRenderingMode(.alwaysTemplate)

            createTransactionButton.setImage(imv?.resize(width: 18), for: .normal)
            createTransactionButton.setTitle("transfer_button_label".localized(), for: .normal)
            createTransactionButton.layer.cornerRadius = 6

//            let ctrl = self.navigationController as! FirstViewController
            if let cnt = navigationController?.viewControllers.count {
                if cnt > 3 {
                    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "home_button_label".localized(), style: .plain, target: self, action: #selector(goToStart))
                    navigationItem.rightBarButtonItem?.tintColor = .white
                }
            }

            // Make back button white
            let backItem = UIBarButtonItem()
            backItem.title = profile.getName()
            backItem.tintColor = .white
            navigationItem.backBarButtonItem = backItem

            check.isHidden = true
            if let ident = profile.identity {
                if let certs = ident.certifications {
                    if certs.count >= 5 {
                        check.isHidden = false
                    }
                }
            }
            
            profile.getBalance(callback: { total in
                let str = String(format: "%@ %.2f %@", "balance_label".localized(), Double(total) / 100, Currency.formattedCurrency(currency: self.currency))

                DispatchQueue.main.async {
                    self.profile?.balance = total
                    self.balance.text = str
                    self.printClassAndFunc(info: "@----- Balance Label = \(str)")
                    self.logClassAndFunc(info: "@----- Balance Label = \(str)")
                    self.balanceReceived()
                }
            })

            // now we can get the history of transactions and show them

            getTransactions(pubKey: profile.issuer)
        }
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(tapGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.shared.appDidBecomeActiveCallback = appDidBecomeActive
        if AppDelegate.shared.g1PaymentRequested != nil {
            createTransaction(createTransactionButton)
        }
    }

    func appDidBecomeActive() {
        if AppDelegate.shared.g1PaymentRequested != nil {
            createTransaction(createTransactionButton)
        }
    }

    func balanceReceived() {
        balanceLoading.stopAnimating()
        transactBtn.isHidden = false
        printClassAndFunc(info: "balanceReceived -> transactBtnHidden = \(transactBtn.isHidden)")
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        print("displaying avatar")
        if displayingAvatar {
            displayingAvatar = false
            avatar.layer.borderWidth = 1
            avatar.layer.masksToBounds = false
            avatar.layer.borderColor = UIColor.white.cgColor
            if #available(iOS 11, *) {
                UIView.animate(withDuration: 0.15, animations: {
                    self.avatar.layer.cornerRadius = 0
                })
            } else {
                avatar.layer.cornerRadius = 0
            }

            avatar.clipsToBounds = true
            if let data = profile?.issuer.data(using: String.Encoding.ascii) {
                if let filter = CIFilter(name: "CIQRCodeGenerator") {
                    filter.setValue(data, forKey: "inputMessage")
                    let transform = CGAffineTransform(scaleX: 3, y: 3)

                    if let output = filter.outputImage?.transformed(by: transform) {
                        tappedImage.image = UIImage(ciImage: output)
                    }
                }
            }
        } else {
            if let prof = profile {
                displayingAvatar = true
                prof.getAvatar(imageView: tappedImage)
                avatar.layer.borderWidth = 1
                avatar.layer.masksToBounds = false
                avatar.layer.borderColor = UIColor.white.cgColor

                if #available(iOS 11, *) {
                    UIView.animate(withDuration: 0.15, animations: {
                        self.avatar.layer.cornerRadius = self.avatar.frame.width / 2
                    })
                } else {
                    avatar.layer.cornerRadius = avatar.frame.width / 2
                }

                avatar.clipsToBounds = true
            }
        }
    }

    @objc func goToStart() {
        if let cnt = navigationController?.viewControllers.count {
            if cnt >= 2 {
                if let secondViewController = navigationController?.viewControllers[1] {
                    navigationController?.popToViewController(secondViewController, animated: true)
                }
            }
        }
    }

    @IBAction func createTransaction(_: UIButton) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)

        let newTransactionView = storyBoard.instantiateViewController(withIdentifier: "NewTransactionView") as! NewTransactionViewController

        newTransactionView.receiver = profile
        let ctrl = navigationController as! FirstViewController
        ctrl.profile = profile
        newTransactionView.sender = profile
        newTransactionView.currency = currency
        newTransactionView.isModalInPopover = true

        printClassAndFunc(info: "@----- sender = \(String(describing: newTransactionView.sender))")
        printClassAndFunc(info: "@----- receiver = \(String(describing: newTransactionView.receiver))")

        navigationController?.present(newTransactionView, animated: true, completion: nil)
        // self.navigationController?.pushViewController(transactionView, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = sections {
            // Only display sections with transactions
            let sects = sections.filter { section -> Bool in
                section.transactions.count > 0
            }
            return sects.count
        }
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = sections {
            let sects = sections.filter { section -> Bool in
                section.transactions.count > 0
            }

            return sects[section].transactions.count
        }
        return 1
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! TransactionTableViewCell
        // DispatchQueue.main.async {
        // let transactionView = self.storyboard!.instantiateViewController(withIdentifier: "MyTransactionView")
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let transactionView = storyBoard.instantiateViewController(withIdentifier: "MyTransactionView") as! TransactionViewController

        if let tx = cell.transaction {
            if tx.pubKey == profile?.issuer {
                print("sender set")
                printClassAndFunc(info: "sender set = \(tx.pubKey)")
                transactionView.sender = profile
            }
            if tx.to.count > 0, tx.to[0] == profile?.issuer {
                print("receiver set")
                printClassAndFunc(info: "reciever set = \(tx.to.count)")
                transactionView.receiver = profile
            }
            if tx.to.count > 0, tx.to[0] == loginProfile?.issuer {
                print("receiver set from login profile")
                printClassAndFunc(info: "reciever set from login = \(tx.to.count)")
                transactionView.receiver = loginProfile
            }
            transactionView.transaction = tx
            transactionView.currency = currency
            transactionView.loginDelegate = self
            transactionView.isModalInPopover = true

            navigationController?.present(transactionView, animated: true, completion: nil)
            // self.navigationController?.pushViewController(transactionView, animated: true)
        }
        // }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrototypeCell", for: indexPath) as! TransactionTableViewCell

        // [0, 0]
        if let sections = sections {
            let sects = sections.filter { section -> Bool in
                section.transactions.count > 0
            }

            let transaction = sects[indexPath[0]].transactions[indexPath[1]]
            cell.transaction = transaction
            let pk = transaction.pubKey
            cell.name?.text = ""

            let date = Date(timeIntervalSince1970: Double(transaction.time))
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "dd/MM/YYYY HH:mm:ss"
            cell.date?.text = dateFormatter.string(from: date)

            let am = Double(truncating: transaction.amount as NSNumber)
            let currency = Currency.formattedCurrency(currency: self.currency)
            cell.amount?.setTitle(String(format: "%.2f \(currency)", am / 100), for: .normal)
            if am <= 0 {
                cell.amount?.backgroundColor = .none
                cell.amount?.layer.borderWidth = 1
                cell.amount?.layer.borderColor = UIColor.brown.cgColor
                cell.amount?.tintColor = .white
            } else {
                cell.amount?.backgroundColor = .none // .init(red: 0, green: 132 / 255.0, blue: 100 / 255.0, alpha: 1)
                cell.amount?.layer.borderColor = UIColor.green.cgColor
                cell.amount?.tintColor = .white
                
                // cell.amount?.titleEdgeInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
            }
            if let frame = cell.amount?.frame {
                cell.amount?.layer.cornerRadius = frame.height / 6 // 2
            }
            let tmpProfile = Profile(issuer: pk)
            tmpProfile.getAvatar(imageView: cell.avatar1)

            // This is two requests per cell, maybe we should get all the users and work with that instead
            Profile.getRequirements(publicKey: pk, callback: { identity in
                var ident = identity
                if identity == nil {
                    ident = Identity(pubkey: pk, uid: "")
                }

                Profile.getProfile(publicKey: pk, identity: ident, callback: { profile in
                    if let prof = profile {
                        cell.profile = prof

                        DispatchQueue.main.async {
                            cell.name?.text = prof.getName()
                        }
                    }
                })
            })
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! TransactionTableViewCell

        if let profile = cell.profile {
            changeUserDelegate?.viewUser(profile: profile)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = sections {
            let sects = sections.filter { section -> Bool in
                section.transactions.count > 0
            }

            return sects[section].type.localized()
        }

        return ""
    }

    func getTransactions(pubKey: String, callback: @escaping (() -> Void) = {}) {
        // https://g1.nordstrom.duniter.org/tx/history/EEdwxSkAuWyHuYMt4eX5V81srJWVy7kUaEkft3CWLEiq
        let url = String(format: "%@/tx/history/%@", currentNode, pubKey)

        let transactionRequest = Request(url: url)
        transactionRequest.jsonDecodeWithCallback(type: TransactionResponse.self, callback: { err, transactionResponse in
            if let currency = transactionResponse?.currency, let history = transactionResponse?.history {
                self.currency = currency
                self.sections = self.parseHistory(history: history, pubKey: pubKey)

                DispatchQueue.main.async { self.tableView?.reloadData() }
            } else if err != nil {
                self.errorAlert(title: "no_internet_title".localized(), message: "no_internet_message".localized())
            }
            callback()
        })
    }

    func errorAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

            self.present(alert, animated: true)
        }
    }

    func parseHistory(history: History, pubKey: String) -> [TransactionSection] {
        var sent = history.sent.map { ParsedTransaction(tx: $0, pubKey: pubKey) }.filter { $0.amount <= 0 }
        var received = history.received.map { ParsedTransaction(tx: $0, pubKey: pubKey) }.filter { $0.amount > 0 }
        var sending = history.sending.map { ParsedTransaction(tx: $0, pubKey: pubKey) }.filter { $0.amount <= 0 }
        var receiving = history.receiving.map { ParsedTransaction(tx: $0, pubKey: pubKey) }.filter { $0.amount > 0 }

        sent.sort { tr1, tr2 -> Bool in
            tr1.time > tr2.time
        }
        received.sort { tr1, tr2 -> Bool in
            tr1.time > tr2.time
        }
        sending.sort { tr1, tr2 -> Bool in
            tr1.time > tr2.time
        }
        receiving.sort { tr1, tr2 -> Bool in
            tr1.time > tr2.time
        }
        return [
            TransactionSection(type: "sent", transactions: sent),
            TransactionSection(type: "received", transactions: received),
            TransactionSection(type: "sending", transactions: sending),
            TransactionSection(type: "receiving", transactions: receiving),
        ]
    }
}

extension ProfileViewController: LoginDelegate {
    func login(profile: Profile) {
        loginProfile = profile
    }
}
