//
//  G1URLPayment.swift
//  shAre
//
//  Created by Eric PAJOT on 26.11.21.
//  Copyright © 2021 Eric PAJOT. All rights reserved.
//

import Foundation

struct G1URLPayment {
    let g1Account: String
    let g1AmountDue: String
    let infoForRecipient: String

    var g1URL: URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "dup"
        urlComponents.host = nil
        urlComponents.path = g1Account
        urlComponents.queryItems = [
            URLQueryItem(name: "amount", value: g1AmountDue),
            URLQueryItem(name: "label", value: infoForRecipient),
        ]
        return urlComponents.url
    }
}

extension G1URLPayment {
    init?(g1URLString: String) {
        guard let components = URLComponents(string: g1URLString) else { return nil }
        guard let urlScheme = components.scheme else { return nil }
        if urlScheme != "dup" { return nil }
        g1Account = components.path
        guard let items = components.queryItems else { return nil }
        let dict = items.reduce(into: [String: String]()) { $0[$1.name] = $1.value }
        g1AmountDue = dict["amount", default: "0.00"]
        infoForRecipient = dict["label", default: ""]
    }
}
