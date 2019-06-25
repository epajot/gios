//
//  Transaction.swift
//  Cesium
//
//  Created by Jonathan Foucher on 31/05/2019.
//  Copyright © 2019 Jonathan Foucher. All rights reserved.
//

import Foundation

struct SourceResponse: Codable {
    var currency: String = "g1"
    var pubkey: String
    var sources: [Source] = []
}

struct Source: Codable {
    var type: String
    var noffset: Int
    var identifier: String
    var amount: Int
    var base: Int
    var conditions: String
}
