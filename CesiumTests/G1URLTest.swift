//
//  g1URLTest.swift
//  shAreTests
//
//  Created by Eric PAJOT on 26.11.21.
//  Copyright © 2021 Eric PAJOT. All rights reserved.
//

import XCTest

class g1URLTest: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testPaymentsG1() {
        let payment = G1URLPayment(g1Account: "XzSqhF4kCGTvfkWM588Ktq9zxCmcjZ3juHLP4anV1sq",
                                g1AmountDue: "10.00",
                                infoForRecipient: "pour vos beaux yeux")

        guard let url = payment.g1URL else {
            XCTFail()
            return
        }
        XCTAssertEqual(url.absoluteString, "g1:XzSqhF4kCGTvfkWM588Ktq9zxCmcjZ3juHLP4anV1sq?amount=10.00&label=pour%20vos%20beaux%20yeux")
        printClassAndFunc(info: "\(url)")

        guard let g1PaymentRecieved = G1URLPayment(g1URLString: url.absoluteString) else {
            XCTFail()
            return
        }
        guard let urlDecoded = g1PaymentRecieved.g1URL else {
            XCTFail()
            return
        }

        XCTAssertEqual(urlDecoded.absoluteString, "g1:XzSqhF4kCGTvfkWM588Ktq9zxCmcjZ3juHLP4anV1sq?amount=10.00&label=pour%20vos%20beaux%20yeux")
        printClassAndFunc(info: "\(url)")
        printClassAndFunc(info: "\(g1PaymentRecieved)")

        XCTAssertEqual(g1PaymentRecieved.g1Account, "XzSqhF4kCGTvfkWM588Ktq9zxCmcjZ3juHLP4anV1sq")
        XCTAssertEqual(g1PaymentRecieved.g1AmountDue, "10.00")
        XCTAssertEqual(g1PaymentRecieved.infoForRecipient, "pour vos beaux yeux")
    }
}
