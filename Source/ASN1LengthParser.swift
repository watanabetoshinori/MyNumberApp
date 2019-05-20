//
//  ASN1LengthParser.swift
//  MyNumberApp
//
//  Created by Watanabe Toshinori on 5/20/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa

public class ASN1LengthParser {
    
    /**
     This function decode the beginning of ASN1 Object and get the length of contents.
     This code has created referring to the following article.
     
     Charles Engelke's Blog: Parsing BER and DER encoded ASN.1 Objects
     https://blog.engelke.com/2014/10/17/parsing-ber-and-der-encoded-asn-1-objects/
     */
    public static func parse(data: Data) -> UInt64 {
        var iterator = data.makeIterator()
        
        // get Tag
        var offset: UInt64 = 0
        var val = iterator.next() ?? 0
        offset += 1
        
        if (val & 0x1F) == 0x1F {
            val = iterator.next() ?? 0
            offset += 1
            while val >= 0x80 {
                val = iterator.next() ?? 0
                offset += 1
            }
        }
        
        // get Length
        val = iterator.next() ?? 0
        offset += 1

        if (val & 0x80) == 0 {
            return offset + UInt64(val)
        } else {
            var data = Data()
            let numberOfDigits = val & 0x7F
            for _ in 0..<numberOfDigits {
                if let n = iterator.next() {
                    offset += 1
                    data.append(n)
                }
            }
            
            if data.count > 8 {
                return 0
            }
            
            var value: UInt64 = 0
            for (i, b) in data.enumerated() {
                let v = UInt64(b) << UInt64(8 * (data.count - i - 1))
                value += v
            }
            return offset + value
        }
    }
    
}
