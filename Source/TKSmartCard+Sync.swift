//
//  TKSmartCard+Sync.swift
//  MyNumberApp
//
//  Created by Watanabe Toshinori on 5/20/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa
import CryptoTokenKit

enum TKConnectionError: Error, LocalizedError {
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "CardReader connection failed."
        }
    }

}

extension TKSmartCard {
    
    // MARK: - Sync functions
    
    class func connect() throws -> TKSmartCard {
        // Get signleton of card reader
        guard let manager = TKSmartCardSlotManager.default else {
            throw TKConnectionError.connectionFailed
        }
        
        // Use the first slot of card reader
        guard let slotName = manager.slotNames.first else {
            throw TKConnectionError.connectionFailed
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var smartCard: TKSmartCard?
        var error: Error?
        
        // Connect to the slot
        manager.getSlot(withName: slotName) { (slot) in
            guard let slot = slot else {
                error = TKConnectionError.connectionFailed
                return
            }
            
            // Create smart card object
            smartCard = slot.makeSmartCard()
            
            if smartCard == nil {
                error = TKConnectionError.connectionFailed
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let smartCard = smartCard {
            return smartCard
        }
        
        throw error!
    }
    
    func beginSession() throws {
        var innerError: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        beginSession { (_, error) in
            innerError = error
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = innerError {
            throw error
        }
    }
    
    func transmit(apdu: [UInt8]) throws -> (sw: UInt16, response: Data) {
        let apduData = Data(bytes: apdu, count: apdu.count)
        
        var innerError: Error?
        var resultData: Data?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        transmit(apduData) { (data, error) in
            innerError = error
            resultData = data
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = innerError {
            print("Failed")
            throw error
        }
        
        // Convert raw data to sw and response
        var bytes = [UInt8](resultData!)
        let sw2 = bytes.removeLast()
        let sw1 = bytes.removeLast()
        
        let sw: UInt16 = UInt16(sw1) << 8 | UInt16(sw2)
        let response = Data(bytes: bytes, count: bytes.count)
        
        print("Success")
        
        return (sw: sw, response: response)
    }

}
