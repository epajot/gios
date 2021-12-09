//
//  NewTransactionViewController.swift
//  Cesium
//
//  Created by Jonathan Foucher on 01/06/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import Foundation
import Sodium
import UIKit

class NewTransactionViewController: UIViewController, UITextViewDelegate {
    var receiver: Profile?
    var sender: Profile?
    var currency: String?

    @IBOutlet var senderAvatar: UIImageView!
    @IBOutlet var receiverAvatar: UIImageView!
    @IBOutlet var arrow: UIImageView!

    @IBOutlet var senderBalance: UILabel!
    @IBOutlet var receiverName: UILabel!
    @IBOutlet var senderName: UILabel!
    @IBOutlet var receiverPubKey: UILabel!
    @IBOutlet var senderPubKey: UILabel!
    @IBOutlet var close: UILabel!
    @IBOutlet var amount: UITextField!
    @IBOutlet var comment: UITextView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var topBarHeight: NSLayoutConstraint!
    @IBOutlet var encryptComment: UISwitch!
    @IBOutlet var encryptCommentSubtext: UILabel!
    @IBOutlet var encryptCommentLabel: UILabel!

    @IBAction func encryptCommentChanged(_ sender: UISwitch) {
        print(sender.isOn)
        if sender.isOn {
            encryptCommentSubtext.text = "encrypt_comment_subtext_yes".localized()
        } else {
            encryptCommentSubtext.text = "encrypt_comment_subtext_no".localized()
        }
    }

    weak var loginView: LoginViewController?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    fileprivate func handleURLRequest() {
        if let g1PaymentRequested = AppDelegate.shared.g1PaymentRequested {
            logClassAndFunc(info: "payment= \(g1PaymentRequested), sender: \(String(describing: sender?.issuer)), receiver: \(String(describing: receiver?.issuer))")

            // app was newly started with a URL payment request
            // we should use g1PaymentRequested here

//            logClassAndFunc(info: "1 = \(g1PaymentRequested.g1Account)")
//            logClassAndFunc(info: "2 = \(g1PaymentRequested.g1AmountDue)")
//            logClassAndFunc(info: "3 = \(g1PaymentRequested.infoForRecipient)")

            amount.text = "\(g1PaymentRequested.g1AmountDue)"
            comment.text = "\(g1PaymentRequested.infoForRecipient)"

            receiver = nil
            receiverProfileFrom(pubKey: g1PaymentRequested.g1Account)

            AppDelegate.shared.g1PaymentRequested = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            print("found")
            topBarHeight.constant = navigationController.navigationBar.frame.height
            view.layoutIfNeeded()
        }

        encryptCommentLabel.text = "encrypt_comment_label".localized()
        encryptCommentSubtext.text = "encrypt_comment_subtext_yes".localized()
        sendButton.layer.cornerRadius = 6

        close.text = "close_label".localized()
        // UIApplication.shared.statusBarStyle = .lightContent
        // set arrow to white
        arrow.tintColor = .white
        arrow.image = UIImage(named: "arrow-right")?.withRenderingMode(.alwaysTemplate)

        progress.progress = 0.0
        amount.addDoneButtonToKeyboard(myAction: #selector(amount.resignFirstResponder))
        comment.addDoneButtonToKeyboard(myAction: #selector(comment.resignFirstResponder))

        comment.text = "comment_placeholder".localized()
        comment.textColor = .lightGray

        receiverAvatar.layer.borderWidth = 1
        receiverAvatar.layer.masksToBounds = false
        receiverAvatar.layer.borderColor = UIColor.white.cgColor
        receiverAvatar.layer.cornerRadius = receiverAvatar.frame.width / 2
        receiverAvatar.clipsToBounds = true

        handleURLRequest()

        if let sender = sender, let receiver = receiver {
            printClassAndFunc(info: "\(sender.issuer), \(receiver.issuer)")
            if sender.issuer == receiver.issuer {
                print("setting to nil")
                self.receiver = nil
                receiverAvatar.image = nil
                receiverName.text = ""
                // This is us, show the user choice view

                changeReceiver(sender: nil)
            }
        }

        if let receiver = receiver {
            receiver.getAvatar(imageView: receiverAvatar)
            receiverName.text = receiver.getName()
        }

        if let sender = sender {
            senderAvatar.layer.borderWidth = 1
            senderAvatar.layer.masksToBounds = false
            senderAvatar.layer.borderColor = UIColor.white.cgColor
            senderAvatar.layer.cornerRadius = receiverAvatar.frame.width / 2
            senderAvatar.clipsToBounds = true

            sender.getAvatar(imageView: senderAvatar)

            senderName.text = sender.getName()
            let cur = Currency.formattedCurrency(currency: currency!)
            if let bal = sender.balance {
                let str = String(format: "%@ %.2f %@", "balance_label".localized(), Double(bal) / 100, cur)
                senderBalance.text = str
            } else {
                sender.getBalance(callback: { total in
                    let str = String(format: "%@ %.2f %@", "balance_label".localized(), Double(total) / 100, cur)
                    self.sender?.balance = total
                    DispatchQueue.main.async {
                        self.senderBalance.text = str
                    }
                })
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.shared.appDidBecomeActiveCallback = appDidBecomeActive
        handleURLRequest()
    }

    func appDidBecomeActive() {
        handleURLRequest()
    }

    func receiverProfileFrom(pubKey: String) {
        Profile.getProfile(publicKey: pubKey, identity: nil) { profile in
            DispatchQueue.main.async {
                if let prof = profile {
                    self.receiverChanged(receiver: prof)
                }
            }
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // move view up a bit
        print(UIScreen.main.bounds.height)
        if UIScreen.main.bounds.height < 700 {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.frame.origin.y -= 100
            })
        }
        if textView.text == "comment_placeholder".localized(), textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)

        if encryptComment.isOn {
            let cipherTextLength = encryptedLength(text: newText)

            return cipherTextLength < 256
        }

        if #"_:/;*[]()?!^\+=@&~#{}|<>%.€,'`"#.contains(text) {
            return false
        }
        let numberOfChars = newText.count
        return numberOfChars < 256
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        // move view down
        if UIScreen.main.bounds.height < 700 {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.frame.origin.y = 0
            })
        }
        if textView.text == "" {
            textView.text = "comment_placeholder".localized()
            textView.textColor = .lightGray
        }
    }

    @IBAction func cancel(sender: UIButton) {
        print("cancel")
        dismiss(animated: true, completion: nil)
    }

    @IBAction func send(sender: UIButton?) {
        print("will send")
        guard let receiver = receiver else {
            changeReceiver(sender: nil)
            return
        }

        let title = receiver.getName()
        guard let currency = currency else {
            print("no currency")
            return
        }
        guard let amstring = amount.text else {
            print("no amount")
            return
        }
        guard let profile = self.sender else {
            print("no sender")
            return
        }

        // Check amount exists
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current

        let am = numberFormatter.number(from: amstring) ?? 0

        if am.floatValue <= 0.0 {
            self.alert(title: "no_amount".localized(), message: "no_amount_message".localized())
            return
        }

        // Check balance
        if let bal = self.sender?.balance {
            if bal < Int(am.floatValue * 100) {
                print(bal, am)
                self.alert(title: "insufficient_funds".localized(), message: "insufficient_funds_message".localized())
                return
            }
        }

        // Show login screen if not logged in
        if let sender = self.sender {
            if sender.kp == nil {
                print("no secret key here")
                sendButton.isEnabled = true
                let storyBoard: UIStoryboard = .init(name: "Main", bundle: nil)

                loginView = storyBoard.instantiateViewController(withIdentifier: "LoginView") as? LoginViewController

                loginView?.loginDelegate = self
                loginView?.sendingTransaction = true
                // loginView.isModalInPopover = true
                if let v = loginView {
                    present(v, animated: true, completion: nil)
                }

                return
            }
        }

        let amountString = String(format: "%.2f %@", Float(truncating: am), Currency.formattedCurrency(currency: currency))

        let msg = String(format: "transaction_confirm_message".localized(), amountString, title)
        let alert = UIAlertController(title: "transaction_confirm_prompt".localized(), message: msg, preferredStyle: .actionSheet)
        print("preparing action")
        alert.addAction(UIAlertAction(title: "transaction_confirm_button_label".localized(), style: .default, handler: { _ in

            self.sendButton.isEnabled = false
            var text = self.comment?.text ?? ""
            if self.comment?.text == "comment_placeholder".localized(), self.comment?.textColor == .lightGray
            {
                text = ""
            }

            if self.encryptComment.isOn {
                if let cipherText = self.encryptComment(text: text) {
                    text = cipherText
                } else {
                    self.errorAlert(message: "comment_encrypt_failed".localized())
                }
            }

            // TODO: validate amount, etc...
            self.progress.setProgress(0.1, animated: true)
            self.sender?.getSources(callback: { (error: Error?, resp: SourceResponse?) in

                if let pk = self.receiver?.issuer, let response = resp {
                    let intAmount = Int(truncating: NSNumber(value: Float(truncating: am) * 100))
                    let url = String(format: "%@/blockchain/current", currentNode)
                    let request = Request(url: url)
                    DispatchQueue.main.async {
                        self.progress.setProgress(0.3, animated: true)
                    }
                    request.jsonDecodeWithCallback(type: Block.self, callback: { (_: Error?, block: Block?) in
                        guard let blk = block else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.progress.setProgress(0.6, animated: true)
                        }
                        do {
                            let signedTx = try Transactions.createTransaction(response: response, receiverPubKey: pk, amount: intAmount, block: blk, comment: text, profile: profile)
                            DispatchQueue.main.async {
                                self.progress.setProgress(0.7, animated: true)
                            }
                            let processUrl = String(format: "%@/tx/process", currentNode)
                            print("processUrl", processUrl)
                            let processRequest = Request(url: processUrl)
                            processRequest.postRaw(rawTx: signedTx, type: Transaction.self, callback: { error, res in

                                if let er = error as? RequestError {
                                    print("ERROR")
                                    if let resp = er.responseData {
                                        print("RESPONSE STRING", String(data: resp, encoding: .utf8)!)
                                        if let jsonDict = try! JSONSerialization.jsonObject(with: resp) as? NSDictionary {
                                            print("JSONDICT", jsonDict)
                                            if let msg = jsonDict["message"] as? String {
                                                DispatchQueue.main.async {
                                                    self.errorAlert(message: String(format: "transaction_fail_text".localized(), msg))
                                                }
                                            }
                                        }
                                    }
                                }
                                if let tx = res {
                                    print("TRANSACTION")
                                    print(tx)

                                    DispatchQueue.main.async {
                                        self.progress.setProgress(1.0, animated: true)
                                        self.cancelButton.isEnabled = true
                                        self.sendButton.isEnabled = true
                                        let alert = UIAlertController(title: "transaction_success_title".localized(), message: "transaction_success_message".localized(), preferredStyle: .actionSheet)

                                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: self.finish))

                                        self.present(alert, animated: true)
                                    }
                                }
                            })

                        } catch TransactionCreationError.insufficientFunds {
                            self.errorAlert(message: String(format: "transaction_fail_text".localized(), "insuficient funds"))
                            print("insuficient funds")
                        } catch TransactionCreationError.couldNotSignTransaction {
                            print("could not sign transaction")
                            self.errorAlert(message: String(format: "transaction_fail_text".localized(), "could not sign transaction"))
                        } catch {
                            self.errorAlert(message: String(format: "transaction_fail_text".localized(), "unknown error"))
                        }
                    })
                }
            })
        }))

        alert.addAction(UIAlertAction(title: "transaction_cancel_button_label".localized(), style: .cancel, handler: finish))
        print("willpresent alert")
        present(alert, animated: true)
    }

    func encryptedLength(text: String) -> Int {
        let sodium = Sodium()

        let sec = sodium.box.keyPair()!
        if let encrypted: Bytes =
            sodium.box.seal(message: Array(text.utf8),
                            recipientPublicKey: sec.publicKey,
                            senderSecretKey: sec.secretKey)
        {
            return String("enc " + Base58.base58FromBytes(encrypted)).count
        }
        return 0
    }

    func encryptComment(text: String) -> String? {
        if let sk = sender?.kp, let pk = receiver?.issuer {
            let sodium = Sodium()

            let sec = sodium.sign.keyPair(seed: Base58.bytesFromBase58(sk))!

            let conv = sodium.sign.convertEd25519KeyPairToCurve25519(keyPair: sec)!
            let recipientPublicKey = sodium.sign.convertEd25519PkToCurve25519(publicKey: Base58.bytesFromBase58(pk))!

            // let msg = String(format: "pk %@ c %@", pk, text)

            if let encrypted: Bytes =
                sodium.box.seal(message: Array(text.utf8),
                                recipientPublicKey: recipientPublicKey,
                                senderSecretKey: conv.secretKey)
            {
                return "enc " + Base58.base58FromBytes(encrypted)
            }
        }
        return nil
    }

    func finish(action: UIAlertAction) {
        DispatchQueue.main.async {
            self.cancelButton.isEnabled = true
            self.sendButton.isEnabled = true
            self.progress.progress = 0.0
            self.comment?.text = "comment_placeholder".localized()
            self.comment?.textColor = .lightGray
            self.amount.text = ""
        }
    }

    func errorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "transaction_fail_title".localized(), message: message, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: self.finish))

            self.present(alert, animated: true)
            self.cancelButton.isEnabled = true
            self.sendButton.isEnabled = true

            self.progress.setProgress(1.0, animated: true)
        }
    }

    func alert(title: String, message: String?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: self.finish))

            self.present(alert, animated: true)
        }
    }

    @IBAction func changeReceiver(sender: UIButton?) {
        DispatchQueue.main.async {
            let storyBoard: UIStoryboard = .init(name: "Main", bundle: nil)

            let changeUserView = storyBoard.instantiateViewController(withIdentifier: "ChangeUserView") as! ChangeReceiverViewController

            changeUserView.isModalInPopover = true
            changeUserView.profileSelectedDelegate = self

            self.present(changeUserView, animated: true, completion: nil)
        }
    }
}

protocol ReceiverChangedDelegate: AnyObject {
    func receiverChanged(receiver: Profile)
}

extension NewTransactionViewController: ReceiverChangedDelegate {
    func receiverChanged(receiver: Profile) {
        self.receiver = receiver
        self.receiver?.getAvatar(imageView: receiverAvatar)
        receiverName.text = receiver.getName()
    }
}

extension NewTransactionViewController: LoginDelegate {
    func login(profile: Profile) {
        sender = profile
        print("in login delegate")
        DispatchQueue.main.async {
            if let v = self.loginView {
                v.dismiss(animated: true, completion: {
                    DispatchQueue.main.async {
                        self.send(sender: nil)
                    }
                })
            }
        }
    }
}
