//
//  TKSmartCard+Command.swift
//  MyNumberApp
//
//  Created by Watanabe Toshinori on 5/20/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa
import CryptoTokenKit
import CommonCrypto

enum TKCommandError: Error, LocalizedError {
    case terminateProcess(status: String)
    
    var errorDescription: String? {
        switch self {
        case .terminateProcess(let status):
            return "Terminate Process: \(status)"
        }
    }

}

extension TKSmartCard {
    
    // MARK: - Commands
    
    func selectMF() throws {
        print("# SELECT MF")
        
        let (sw, _) = try send(ins: 0xA4, p1: 0x00, p2: 0x00)
        
        let status = String(sw, radix: 16)
        if status != "9000" {
            throw TKCommandError.terminateProcess(status: status)
        }
        
        print("Success")
    }
    
    func selectDF(_ fileID: [UInt8]) throws {
        print("# SELECT DF")
        
        let data = Data(bytes: fileID, count: fileID.count)
        let (sw, _) = try send(ins: 0xA4, p1: 0x04, p2: 0x0c, data: data, le: nil)
        
        let status = String(sw, radix: 16)
        if status != "9000" {
            throw TKCommandError.terminateProcess(status: status)
        }
        
        print("Success")
    }
    
    func selectEF(_ fileID: [UInt8]) throws {
        print("# SELECT EF")
        
        let data = Data(bytes: fileID, count: fileID.count)
        let (sw, _) = try send(ins: 0xA4, p1: 0x02, p2: 0x0C, data: data, le: nil)
        
        let status = String(sw, radix: 16)
        if status != "9000" {
            throw TKCommandError.terminateProcess(status: status)
        }
        
        print("Success")
    }
    
    func verify(pin: String) throws {
        print("# VERIFY")
        
        let pinBytes = [UInt8](pin.data(using: .ascii)!)
        let data = Data(bytes: pinBytes, count: pinBytes.count)
        let (sw, _) = try send(ins: 0x20, p1: 0x00, p2: 0x80, data: data, le: nil)
        
        let status = String(sw, radix: 16)
        if status != "9000" {
            throw TKCommandError.terminateProcess(status: status)
        }
        
        print("Success")
    }
    
    func retryCount() throws -> Int {
        print("# VERIFY")
        
        let (sw, _) = try send(ins: 0x20, p1: 0x00, p2: 0x80)
        
        let status = String(sw, radix: 16)
        let count = Int(status.group(by: #"PIN verification failed, ([0-9]+) tries left"#, at: 1) ?? "0")
        
        print("Success")
        
        return count ?? 0
    }
    
    func readBinary(length: Int = 0) throws -> Data {
        print("# READ BINARY")
        
        if length == 0 {
            let (sw, data) = try send(ins: 0xB0, p1: 0x00, p2: 0x00, data: nil, le: 0)
            
            let status = String(sw, radix: 16)
            if status != "9000" {
                throw TKCommandError.terminateProcess(status: status)
            }
            
            return data
            
        } else {
            // Read per 255 bytes
            
            var data = Data()
            
            while data.count < length {
                let offset = data.count
                let p1 = UInt8((offset >> 8) & 0xFF)
                let p2 = UInt8(offset & 0xFF)
                let l: Int = {
                    let diff = (length - offset)
                    return diff <= 0xFF ? diff : 0
                }()
                
                let (sw, responseData) = try send(ins: 0xB0, p1: p1, p2: p2, data: nil, le: Int(l))

                let status = String(sw, radix: 16)
                if status != "9000" {
                    throw TKCommandError.terminateProcess(status: status)
                }
                
                data.append(responseData)
            }
            
            return data
        }
    }
    
    func computeDigitalSignature(data: Data) throws -> Data {
        print("# COMPUTE DIGITAL SIGNATURE")
        
        let digestInfo = generateDigestInfo(with: data)
        let apdu: [UInt8] = [0x80, 0x2A, 0x00, 0x80, 0x23] + digestInfo + [0x00]
        
        let (sw, responseData) = try transmit(apdu: apdu)
        
        let status = String(sw, radix: 16)
        if status != "9000" {
            throw TKCommandError.terminateProcess(status: status)
        }
        
        print("Success")

        return responseData
    }
    
    // MARK: - Generate DigestInfo for signing
    
    private func generateDigestInfo(with data: Data) -> [UInt8] {
        // Calculate SHA1 digest
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { (ptr) in
            guard let baseAddress = ptr.baseAddress else {
                return
            }
            _ = CC_SHA1(baseAddress, CC_LONG(data.count), &digest)
        }
        
        /*
         DeigestInfo:: = SEQUENCE {
            SEQUENCE {
                OBJECT IDENTIFIER
                NULL
            }
            OCTET STRING
         }
         */
        let header: [UInt8] = [
            // SEQUENCE
            0x30,
            0x21,
            // SEQUENCE
            0x30,
            0x09,
            // OBJECT IDENTIFIER
            0x06,
            0x05,
            0x2B,  0x0E,  0x03, 0x02, 0x1A,
            // NULL
            0x05,
            0x00,
            // OCTET STRING
            0x04,
            0x14
        ]
        let digestInfo = header + digest

        return digestInfo
    }
    
}
