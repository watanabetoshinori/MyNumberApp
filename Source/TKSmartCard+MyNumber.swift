//
//  TKSmartCard+MyNumber.swift
//  MyNumberApp
//
//  Created by Watanabe Toshinori on 5/20/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa
import CryptoTokenKit

enum CardApplication {
    case jpki
    case cardFace
    case cardText
    
    var identifier: [UInt8] {
        switch self {
        case .jpki:
            return [0xD3, 0x92, 0xF0, 0x00, 0x26, 0x01, 0x00, 0x00, 0x00, 0x01]
        case .cardFace:
            return [0xD3, 0x92, 0x10, 0x00, 0x31, 0x00, 0x01, 0x01, 0x04, 0x02]
        case .cardText:
            return [0xD3, 0x92, 0x10, 0x00, 0x31, 0x00, 0x01, 0x01, 0x04, 0x08]
        }
    }

}

/**
    JPKI-AP
 */
enum JPKIApplication {
    case token
    case authPIN
    case authCert
    case authCACert
    case authPrivateKey
    case signPIN
    case signCert
    case signCACert
    case signPrivateKey
    
    var identifier: [UInt8] {
        switch self {
        case .token:
            return [0x00, 0x06]
        case .authPIN:
            return [0x00, 0x18]
        case .authCert:
            return [0x00, 0x0A]
        case .authCACert:
            return [0x00, 0x0B]
        case .authPrivateKey:
            return [0x00, 0x17]
        case .signPIN:
            return [0x00, 0x1B]
        case .signCert:
            return [0x00, 0x01]
        case .signCACert:
            return [0x00, 0x02]
        case .signPrivateKey:
            return [0x00, 0x1A]
        }
    }

}

/**
    券面 AP
 */
enum CardFaceApplication {
    case pin
    case front
    
    var identifier: [UInt8] {
        switch self {
        case .pin:
            return [0x00, 0x13]
        case .front:
            return [0x00, 0x02]
        }
    }

}

/**
    券面事項入力補助 AP
 */
enum CardTextApplication {
    case pin
    case myNumber
    case basicData
    
    var identifier: [UInt8] {
        switch self {
        case .pin:
            return [0x00, 0x11]
        case .myNumber:
            return [0x00, 0x01]
        case .basicData:
            return [0x00, 0x02]
        }
    }

}

enum TKMyNumberError: Error, LocalizedError {
    case invalidData(Data)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let data):
            let hexString = data.map { String(format: "%02X", $0) }.joined()
            return "Invalid Data: \(hexString)"
        }
    }
    
}

extension TKSmartCard {
    
    // MARK: - マイナンバー

    /**
        利用者証明用電子証明書の証明書を取得します
     */
    func getAuthCert() throws -> Data {
        try selectDF(CardApplication.jpki.identifier)

        try selectEF(JPKIApplication.authCert.identifier)
        let lengthData = try readBinary(length: 7)
        let length = ASN1LengthParser.parse(data: lengthData)
        let certData = try readBinary(length: Int(length))

        return certData
    }
    
    /**
        利用者証明用電子証明書の CA 証明書を取得します
     */
    func getAuthCACert() throws -> Data {
        try selectDF(CardApplication.jpki.identifier)

        try selectEF(JPKIApplication.authCACert.identifier)
        let lengthData = try readBinary(length: 7)
        let length = ASN1LengthParser.parse(data: lengthData)
        let certData = try readBinary(length: Int(length))
        
        return certData
    }
    
    /**
        署名用電子証明書の証明書を取得します
     */
    func getSignCert(with pin: String) throws -> Data {
        try selectDF(CardApplication.jpki.identifier)

        // PIN
        try selectEF(JPKIApplication.signPIN.identifier)
        try verify(pin: pin)
        
        try selectEF(JPKIApplication.signCert.identifier)
        let lengthData = try readBinary(length: 7)
        let length = ASN1LengthParser.parse(data: lengthData)
        let certData = try readBinary(length: Int(length))
        
        return certData
    }

    /**
        署名用電子証明書の CA 証明書を取得します
     */
    func getSignCertCA() throws -> Data {
        try selectDF(CardApplication.jpki.identifier)

        try selectEF(JPKIApplication.signCACert.identifier)
        let lengthData = try readBinary(length: 7)
        let length = ASN1LengthParser.parse(data: lengthData)
        let certData = try readBinary(length: Int(length))
        
        return certData

    }

    /**
        指定したデータに対する署名を取得します
     
        - parameters:
            - pin: 利用者証明用電子証明書の暗証番号
            - data: 署名対象のデータ
     */
    func getSign(with pin: String, for data: Data) throws -> Data {
        try selectDF(CardApplication.jpki.identifier)
        
        // PIN
        try selectEF(JPKIApplication.authPIN.identifier)
        try verify(pin: pin)

        try selectEF(JPKIApplication.authPrivateKey.identifier)
        let signedData = try computeDigitalSignature(data: data)
        return signedData
    }
    
    /**
        カード券面を取得します

         - parameters:
            - pin: マイナンバー
     */
    func getCardFront(with pin: String) throws -> Data {
        try selectDF(CardApplication.cardFace.identifier)

        // PIN
        try selectEF(CardFaceApplication.pin.identifier)
        try verify(pin: pin)

        try selectEF(CardFaceApplication.front.identifier)
        let lengthData = try readBinary(length: 7)
        let length = ASN1LengthParser.parse(data: lengthData)
        let faceData = try readBinary(length: Int(length))
        
        return faceData
    }
    
    /**
        マイナンバーを取得します
     
        - parameters:
            - pin: 券面事項入力補助用暗証番号
        - returns:
            マイナンバー
     */
    func getMyNumber(with pin: String) throws -> String {
        try selectDF(CardApplication.cardText.identifier)
        
        // PIN
        try selectEF(CardTextApplication.pin.identifier)
        try verify(pin: pin)

        try selectEF(CardTextApplication.myNumber.identifier)
        let data = try readBinary(length: 15)
        
        let myNumberData = data.subdata(in: Range(3...14))
        
        guard let myNumber = String(data: myNumberData, encoding: .ascii) else {
                throw TKMyNumberError.invalidData(data)
        }

        return myNumber
    }
    
    /**
        4情報（住所/氏名/生年月日/性別）を取得します
     
         - parameters:
            - pin: 券面事項入力補助用暗証番号
     */
    func getBasicData(with pin: String) throws -> Data {
        try selectDF(CardApplication.cardText.identifier)
        
        // PIN
        try selectEF(CardTextApplication.pin.identifier)
        try verify(pin: pin)
        
        try selectEF(CardTextApplication.basicData.identifier)
        let lengthData = try readBinary(length: 7)
        let length = ASN1LengthParser.parse(data: lengthData)
        let basicData = try readBinary(length: Int(length))
        
        return basicData
   }
    
}
