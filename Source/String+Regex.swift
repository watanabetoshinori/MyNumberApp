//
//  String+Regex.swift
//  MyNumberApp
//
//  Created by Watanabe Toshinori on 5/20/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa

extension String {
    
    func group(by pattern: String, at index: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
            let matched = regex.firstMatch(in: self, range: NSRange(location: 0, length: count)) else {
                return nil
        }
        
        return (self as NSString).substring(with: matched.range(at: index))
    }
    
}
