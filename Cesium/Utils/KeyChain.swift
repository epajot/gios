//
//  KeyChain.swift
//  Cesium
//
//  Created by Jonathan Foucher on 16/06/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import Foundation

class KeyChain {
    
    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef: AnyObject? = nil
        
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    
    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)
        
        let swiftString: String = cfStr as String
        return swiftString
    }
}

extension Data {
    
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
    
    // https://stackoverflow.com/questions/60857760/warning-initialization-of-unsafebufferpointert-results-in-a-dangling-buffer
    
//    init<T>(value: T) {
//           self = withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) -> Data in
//               return Data(buffer: UnsafeBufferPointer(start: ptr, count: 1))
//           }
//       }
//
//       mutating func append<T>(value: T) {
//           withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) in
//               append(UnsafeBufferPointer(start: ptr, count: 1))
//           }
//       }
    
}
