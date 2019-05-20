//
//  ViewController.swift
//  MyNumberApp
//
//  Created by Watanabe Toshinori on 5/20/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa
import CryptoTokenKit

class ViewController: NSViewController {
    
    @IBOutlet weak var authPINField: NSTextField!

    @IBOutlet weak var textToSignField: NSTextField!

    @IBOutlet weak var signPINField: NSTextField!
    
    @IBOutlet weak var cardTextPINField: NSTextField!

    @IBOutlet weak var myNumberField: NSTextField!

    // MARK: - ViewController lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print(documentDirectoryURL)
    }
    
    // MARK: - Represented Object

    override var representedObject: Any? {
        didSet {

        }
    }
    
    // MARK: - JPKI AP actions
    
    @IBAction func showAuthCertTapped(_ sender: Any) {
        do {
            // Connect
            let card = try TKSmartCard.connect()
            
            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }

            let data = try card.getAuthCert()
            
            save(data: data, fileName: "AuthCert.der")
            
        } catch {
            alert(error)
        }
    }

    @IBAction func showAuthCACertTapped(_ sender: Any) {
        do {
            // Connect
            let card = try TKSmartCard.connect()
            
            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }
            
            let data = try card.getAuthCACert()

            save(data: data, fileName: "AuthCACert.der")

        } catch {
            alert(error)
        }
    }

    @IBAction func getSign(_ sender: Any) {
        do {
            let pin = authPINField.stringValue
            
            if pin.isEmpty {
                alert("暗証番号を入力してください")
                return
            }
            
            if pin.count != 4 {
                alert("暗証番号は4文字で入力してください")
                return
            }
            
            let textToSign = textToSignField.stringValue
            
            if textToSign.isEmpty {
                alert("テキストを入力してください")
                return
            }
            
            // Connect
            let card = try TKSmartCard.connect()
            
            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }
            
            let dataToSign = textToSign.data(using: .utf8)!
            let data = try card.getSign(with: pin, for: dataToSign)
            
            save(data: data, fileName: "JPKI.sig")
            
        } catch {
            alert(error)
        }
    }

    @IBAction func showSignCertTapped(_ sender: Any) {
        do {
            let pin = signPINField.stringValue
            
            if pin.isEmpty {
                alert("暗証番号を入力してください")
                return
            }
            
            if pin.count < 6 && 16 < pin.count {
                alert("暗証番号は6文字〜16文字で入力してください")
                return
            }

            // Connect
            let card = try TKSmartCard.connect()
            
            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }
            
            let data = try card.getSignCert(with: pin)

            save(data: data, fileName: "SignCert.der")

        } catch {
            alert(error)
        }
    }

    @IBAction func showSignCACertTapped(_ sender: Any) {
        do {
            // Connect
            let card = try TKSmartCard.connect()
            
            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }
            
            let data = try card.getSignCertCA()

            save(data: data, fileName: "SignCACert.der")

        } catch {
            alert(error)
        }
    }
    
    // MARK: - CardText AP actions

    @IBAction func showMyNumberTapped(_ sender: Any) {
        do {
            let pin = cardTextPINField.stringValue

            if pin.isEmpty {
                alert("暗証番号を入力してください")
                return
            }

            if pin.count != 4 {
                alert("暗証番号は4文字で入力してください")
                return
            }

            // Connect
            let card = try TKSmartCard.connect()

            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }

            let myNumber = try card.getMyNumber(with: pin)
            alert("マイナンバー: \(myNumber)")

        } catch {
            alert(error)
        }
    }
    
    @IBAction func showBasicDataTapped(_ sender: Any) {
        do {
            let pin = cardTextPINField.stringValue

            if pin.isEmpty {
                alert("暗証番号を入力してください")
                return
            }

            if pin.count != 4 {
                alert("暗証番号は4文字で入力してください")
                return
            }

            // Connect
            let card = try TKSmartCard.connect()

            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }

            let data = try card.getBasicData(with: pin)

            save(data: data, fileName: "BasicData.data")

        } catch {
            alert(error)
        }
    }

    // MARK: - CardImage AP actions
    
    @IBAction func showCardFrontTapped(_ sender: Any) {
        do {
            let myNumber = myNumberField.stringValue
            
            if myNumber.isEmpty {
                alert("マイナンバーを入力してください")
                return
            }
            
            if myNumber.count != 12 {
                alert("マイナンバーは12文字で入力してください")
                return
            }

            // Connect
            let card = try TKSmartCard.connect()
            
            // Begin session
            try card.beginSession()
            defer {
                card.endSession()
            }
            
            let data = try card.getCardFront(with: myNumber)
            
            save(data: data, fileName: "CardFront.data")
            
        } catch {
            alert(error)
        }
    }

    // MARK: - Save file
    
    private func save(data: Data, fileName: String) {
        // print(data.map { String(format: "%0X", $0) }.joined())

        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)

            // Open directory
            NSWorkspace.shared.activateFileViewerSelecting([documentDirectoryURL])
            
        } catch {
            alert(error)
        }
    }
    
    // MARK: - Show Alert

    private func alert(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func alert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
}
