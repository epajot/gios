//
//  ResourceDataUrl.swift v.0.2.0
//  shAre
//
//  Created by Rudolf Farkas on 04.06.20.
//  Copyright © 2020 Eric PAJOT. All rights reserved.
//

import Foundation

/// Encapsulates data related to a Share resource and provides conversions to and from an URL string
struct ResourceDataUrl: Codable, Equatable {
    // TODO: which properties could be optional, which required?
    private(set) var scheme: String
    private(set) var calendarTitle: String
    private(set) var email: String
    private(set) var price: String
    private(set) var distPrice: String
    private(set) var distUnit: String
    private(set) var currency: String
    private(set) var options: Int

    /// Encode resource data into an URL query string
    var encodedUrlString: String? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "calshare"
        urlComponents.host = ""
        urlComponents.path = ""
        urlComponents.queryItems = [
            URLQueryItem(name: "R", value: calendarTitle),
            URLQueryItem(name: "M", value: email),
            URLQueryItem(name: "P", value: price),
            URLQueryItem(name: "D", value: distPrice),
            URLQueryItem(name: "U", value: distUnit),
            URLQueryItem(name: "C", value: currency),
            URLQueryItem(name: "O", value: String(options)),
        ]
        guard let url = urlComponents.url else { return nil }
        return url.absoluteString
    }

    /// Return an encrypted url string containing the properties of self
    var encryptedUrlString: String? {
        guard let encodedUrlString2 = encodedUrlString else { return nil }
        let string = encodedUrlString2.replacingOccurrences(of: "calshare://", with: "")

        guard let encrypted = CryptoExt.encryptIntoString64(string: string) else { return nil }
        return "\(scheme)://\(encrypted)"
    }
}

extension ResourceDataUrl {
    /// Initialize from a ResourceData instance for encoding
    init?(resourceData: ResourceData, withScheme: String = "calshare") {
        scheme = withScheme
        calendarTitle = resourceData.calendarTitle
        email = resourceData.email
        price = resourceData.price.perHour
        distPrice = resourceData.price.perDistanceUnit
        distUnit = resourceData.price.distanceUnit
        currency = resourceData.price.currency
        options = resourceData.options
        if scheme == "" { return nil }
    }

    /// Initialize resource data from an URL string for decoding
    init?(encodedUrlString: String, withScheme: String = "calshare") {
        let components = URLComponents(string: encodedUrlString)
        guard let urlScheme = components?.scheme else { return nil }
        if urlScheme != withScheme { return nil }
        scheme = urlScheme
        guard let items = components?.queryItems else { return nil }
        let dict = items.reduce(into: [String: String]()) { $0[$1.name] = $1.value }
        calendarTitle = dict["R", default: ""]
        email = dict["M", default: ""]
        price = dict["P", default: ""]
        distPrice = dict["D", default: ""]
		distUnit = dict["U", default: ""]
        currency = dict["C", default: ""]
        options = Int(dict["O", default: "0"]) ?? 0
    }

    /// Initialize from an encrypted url string for decoding
    init?(encryptedUrlString: String, withScheme: String = "calshare") {
        let elements = encryptedUrlString.components(separatedBy: "://")
        guard elements.count == 2 else { return nil }
        guard elements[0] == withScheme else { return nil }

        let encrypted = elements[1]
        guard let decryptedUrlQueryString = CryptoExt.decryptIntoString(string64: encrypted) else { return nil }

        let components = URLComponents(string: "DUMMY://\(decryptedUrlQueryString)")
        guard let items = components?.queryItems else { return nil }

        let dict = items.reduce(into: [String: String]()) { $0[$1.name] = $1.value }

        scheme = "calshare"
        calendarTitle = dict["R", default: ""]
        email = dict["M", default: ""]
        price = dict["P", default: ""]
        distPrice = dict["D", default: ""]
        distUnit = dict["U", default: ""]
        currency = dict["C", default: ""]
        options = Int(dict["O", default: "0"]) ?? 0
    }

    // TODO:
    init?(encodedOrEncryptedUrlString: String, withScheme: String = "calshare") {
        return nil
    }

    /// Return json-encoded string
    var jsonString: String? {
        return encode()
    }
}
