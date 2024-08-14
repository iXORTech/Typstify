//
//  Hashing.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-08-05.
//

import Foundation
import CryptoKit

extension Data {
    var MD5: String {
        let computed = Insecure.MD5.hash(data: self)
        return computed.map { String(format: "%02hhx", $0) }.joined()
    }
}
