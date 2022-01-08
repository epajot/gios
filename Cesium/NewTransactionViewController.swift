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
    var encryptedComentON = true
    var qrcodeDisplayed: Bool = false

    @IBOutlet var senderAvatar: UIImageView!
    @IBOutlet var receiverAvatar: UIImageView!
    @IBOutlet var visibleComment: UIButton!

    @IBOutlet var senderBalance: UILabel!
    @IBOutlet var receiverName: UILabel!
    @IBOutlet var senderName: UILabel!
    @IBOutlet var receiverPubKey: UILabel!
    @IBOutlet var senderPubKey: UILabel!
    @IBOutlet var close: UILabel!
    @IBOutlet var amount: UITextField!
    @IBOutlet var comment: UITextView!
    @IBOutlet var transfertBtn: UIButton!
    @IBOutlet var cancelButton: UIButton!
//    @IBOutlet var sendButton: UIButton!
    @IBOutlet var transferBtn: UIButton!
    @IBOutlet var cleanUpBtn: UIButton!
    @IBOutlet var qrcodeBtn: UIButton!
    @IBOutlet var scanBtn: UIButton!
    @IBOutlet var balanceLoading: UIActivityIndicatorView!
    
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var topBarHeight: NSLayoutConstraint!
    @IBOutlet var encryptComment: UISwitch!
    @IBOutlet var encryptCommentSubtext: UILabel!
    @IBOutlet var encryptCommentLabel: UILabel!

    @IBAction func encryptCommentChanged(_ sender: UISwitch) {
        vibrateLight()
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
            
            receiver = nil
            receiverProfileFrom(pubKey: g1PaymentRequested.g1Account)
            amount.text = "\(g1PaymentRequested.g1AmountDue)"
            refactorAmountWithDot()
            comment.text = "\(g1PaymentRequested.infoForRecipient)"
            commentChangeColor()

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

        balanceLoading.startAnimating()
        balanceLoading.isHidden = false
        
        displayTransfertImageFliped()
        transfertBtn.clipsToBounds = true
        transfertBtn.tintColor = .blue
        transfertBtn.isHidden = true

        amount.keyboardType = UIKeyboardType.decimalPad
        amount.addDoneButtonToKeyboard(myAction: #selector(amount.resignFirstResponder))
        amount.layer.backgroundColor = UIColor(named: "EP_Blue")?.cgColor //UIColor.white.cgColor
        amount.layer.borderColor = UIColor(named: "EP_Blue")?.cgColor //UIColor.white.cgColor
        amount.layer.cornerRadius = 6
        amount.layer.borderWidth = 1
        amount.attributedPlaceholder = NSAttributedString(
            string: "no_amount".localized(),
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])

        refactorAmountWithDot()
        senderBalance.isHidden = true

        encryptCommentLabel.text = "encrypt_comment_label".localized()
        encryptedTextLabelDisplay()

//        sendButton.layer.cornerRadius = 6

        close.text = "close_label".localized()
        // UIApplication.shared.statusBarStyle = .lightContent

        progress.progress = 0.0

        comment.text = "comment_placeholder".localized()
        
        handleURLRequest()

        commentChangeColor()

        comment.addDoneButtonToKeyboard(myAction: #selector(comment.resignFirstResponder))

        receiverAvatar.layer.borderWidth = 1
        receiverAvatar.layer.masksToBounds = false
        receiverAvatar.layer.borderColor = UIColor.white.cgColor
        receiverAvatar.layer.backgroundColor = .none
        receiverAvatar.layer.cornerRadius = receiverAvatar.frame.width / 2
        receiverAvatar.layer.masksToBounds = false
        receiverAvatar.clipsToBounds = true

//        let imv = UIImage(named: "g1")?.withRenderingMode(.alwaysTemplate)
//        sendButton.setImage(imv?.resize(width: 18), for: .normal)
//        sendButton.setTitle("transfer_button_label".localized(), for: .normal)
//        sendButton.layer.borderColor = UIColor.darkGray.cgColor
//        sendButton.layer.cornerRadius = 6
//        sendButton.layer.borderWidth = 1

        if let sender = sender, let receiver = receiver {
            if sender.issuer == receiver.issuer {
                print("setting to nil")
                self.receiver = nil
                receiverAvatar.image = nil
                receiverName.text = ""
                // This is us, show the user choice view
                // changeReceiver()
                printClassAndFunc(info: "\(sender.issuer), \(receiver.issuer)")
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
            if let bal = sender.balance {
                let cur = Currency.formattedCurrency(currency: currency!)
                let str = String(format: "%@ %.2f %@", "balance_label".localized(), Double(bal) / 100, cur)
                senderBalance.text = str
            } else {
                sender.getBalance2(callback: { total, currency in
                    let cur2 = Currency.formattedCurrency(currency: currency)
                    let str = String(format: "%@ %.2f %@", "balance_label".localized(), Double(total) / 100, cur2)
                    self.sender?.balance = total
                    DispatchQueue.main.async {
                        self.senderBalance.text = str
                        self.balanceReceived()
                    }
                })
            }
        }
        
        if sender?.balance != nil {
            self.balanceReceived()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.shared.appDidBecomeActiveCallback = appDidBecomeActive
        handleURLRequest()
        commentChangeColor()
    }
    
    func balanceReceived() {
        balanceLoading.stopAnimating()
        balanceLoading.isHidden = true
        transfertBtn.isHidden = false
        senderBalance.isHidden = false
    }
    
    func appDidBecomeActive() {
        handleURLRequest()
    }

    fileprivate func refactorAmountWithDot() {
        // EP's Test replacing comma with dot into amount.text
        amount.text = amount.text?.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil)
    }

    func displayTransfertImageFliped() {
        if qrcodeDisplayed {
            transfertBtn.setImage(UIImage(named: "arrow-right")?.withHorizontallyFlippedOrientation(), for: .normal)
        } else {
            transfertBtn.setImage(UIImage(named: "arrow-right"), for: .normal)
        }
    }

    func commentChangeColor() {
        visibleComment.tintColor = encryptedComentON ? .orange : .white
        encryptCommentSubtext.textColor = visibleComment.tintColor
        if comment.text == "comment_placeholder".localized() {
            comment.textColor = .darkGray
        } else {
            comment.textColor = visibleComment.tintColor
        }
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
        if textView.text == "comment_placeholder".localized(), textView.textColor == .darkGray {
            textView.text = ""
            commentChangeColor()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)

        if encryptedComentON {
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
            commentChangeColor()
        }
    }

    func readQRCode() {
        DispatchQueue.main.async {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)

            let QRCodeView = storyBoard.instantiateViewController(withIdentifier: "QRCodeView") as! QRCodeViewController

            QRCodeView.isModalInPopover = true
            QRCodeView.profileSelectedDelegate = self

            self.present(QRCodeView, animated: true, completion: nil)
        }
    }

    fileprivate func encryptedTextLabelDisplay() {
        if encryptedComentON {
            if #available(iOS 13.0, *) {
                visibleComment.setImage(UIImage(systemName: "eye.slash"), for: .normal)
                encryptCommentSubtext.text = "encrypt_comment_subtext_yes".localized()
            } else {
                // Fallback on earlier versions
            }
        } else {
            if #available(iOS 13.0, *) {
                visibleComment.setImage(UIImage(systemName: "eyeglasses"), for: .normal)
                encryptCommentSubtext.text = "encrypt_comment_subtext_no".localized()
            } else {
                // Fallback on earlier versions
            }
        }
    }

    @IBAction func qrcodeBtnTapped(_ sender: Any) {
        qrcodeDisplayed.toggle()
//        displayTransfertImageFliped()
        vibrateLight()
        
        if qrcodeDisplayed {
            senderAvatar.layer.masksToBounds = false
            if #available(iOS 11, *) {
                UIView.animate(withDuration: 0.15, animations: {
                    self.senderAvatar.layer.cornerRadius = 0
                })
            } else {
                senderAvatar.layer.cornerRadius = 0
            }
            senderAvatar.clipsToBounds = true
            if let data = self.sender?.issuer.data(using: String.Encoding.ascii) {
                if let filter = CIFilter(name: "CIQRCodeGenerator") {
                    filter.setValue(data, forKey: "inputMessage")
                    let transform = CGAffineTransform(scaleX: 3, y: 3)
                    if let output = filter.outputImage?.transformed(by: transform) {
                        senderAvatar.image = UIImage(ciImage: output)
                    }
                }
            }
        } else {
            if let prof = self.sender {
                prof.getAvatar(imageView: senderAvatar)
                senderAvatar.layer.masksToBounds = false
                if #available(iOS 11, *) {
                    UIView.animate(withDuration: 0.15, animations: {
                        self.senderAvatar.layer.cornerRadius = self.senderAvatar.frame.width / 2
                    })
                } else {
                    senderAvatar.layer.cornerRadius = senderAvatar.frame.width / 2
                }
                senderAvatar.clipsToBounds = true
            }
        }
    }

    @IBAction func cleanUpBtnTapped(_ sender: Any) {
        vibrateLight()
//        amount.text = nil
//        comment.text = "comment_placeholder".localized()
//        commentChangeColor()

        print("Clean Up")
    }
    
    @IBAction func scanBtnTapped(_ sender: Any) {
//        printClassAndFunc(info: "Scan Btn Tapped !!")
        vibrateLight()
        readQRCode()
    }

    @IBAction func senderAvatarTapped(_ sender: UITapGestureRecognizer) {
        vibrateLight()
        printClassAndFunc(info: "sender Avatar Tapped !!!")
        dismiss(animated: true, completion: nil)
    }

    @IBAction func visibleCommentTapped(_ sender: Any) {
        vibrateLight()
        encryptedComentON.toggle()
        encryptedTextLabelDisplay()
        commentChangeColor()
    }

    @IBAction func cancel(sender: UIButton) {
        vibrateLight()
        print("cancel")
        dismiss(animated: true, completion: nil)
    }

    fileprivate func changeReceiver() {
        DispatchQueue.main.async {
            let storyBoard: UIStoryboard = .init(name: "Main", bundle: nil)

            let changeUserView = storyBoard.instantiateViewController(withIdentifier: "ChangeUserView") as! ChangeReceiverViewController

            changeUserView.isModalInPopover = true
            changeUserView.profileSelectedDelegate = self

            self.present(changeUserView, animated: true, completion: nil)
        }
    }

    @IBAction func tapToChangeReceiver(_ sender: UITapGestureRecognizer) {
        vibrateLight()
        print("Change Receiver Tapped !!!")
        changeReceiver()
    }

    @IBAction func transfertBtnTapped(_ sender: Any) {
        vibrateLight()
        print("Transfert Amount Tapped !!!")
        changeReceiver()
    }

    @IBAction func receiverAndChangeTapped(_ sender: UIButton?) {
        vibrateLight()
//    }
//
//    @IBAction func send(sender: UIButton?) {
        print("will send")
        guard let receiver = receiver else {
            changeReceiver()
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

        printClassAndFunc(info: "amstring = \(amstring) !!!") // EP's Check

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
                transferBtn.isEnabled = true

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

        printClassAndFunc(info: "amountString = \(amountString) !!!") // EP's Check

        let msg = String(format: "transaction_confirm_message".localized(), amountString, title)
        let alert = UIAlertController(title: "transaction_confirm_prompt".localized(), message: msg, preferredStyle: .actionSheet)
        print("preparing action")
        alert.addAction(UIAlertAction(title: "transaction_confirm_button_label".localized(), style: .default, handler: { _ in

            self.transferBtn.isEnabled = false

            var text = self.comment?.text ?? ""
            if self.comment?.text == "comment_placeholder".localized(), self.comment?.textColor == .darkGray
            {
                text = ""
            }

            if self.encryptedComentON {
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
                                        self.transferBtn.isEnabled = true

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
            self.transferBtn.isEnabled = true

            self.progress.progress = 0.0
            self.comment?.text = "comment_placeholder".localized()
            self.comment?.textColor = .darkGray
            self.amount.text = ""
        }
    }

    func errorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "transaction_fail_title".localized(), message: message, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: self.finish))

            self.present(alert, animated: true)
            self.cancelButton.isEnabled = true
            self.transferBtn.isEnabled = true

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
//                        self.send(sender: nil)
                        self.receiverAndChangeTapped(nil)
                    }
                })
            }
        }
    }
}
