//
//  AddressTests.swift
//
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
@testable import BitcoinKit

class AddressTests: XCTestCase {
    
    func testMainnetLegacyAddress() {
        let privateKey = try! PrivateKey(wif: "5K6EwEiKWKNnWGYwbNtrXjA8KKNntvxNKvepNqNeeLpfW7FSG1v")
        let publicKey = privateKey.publicKey()
        let addressFromPublicKey = publicKey.toLegacy()
        XCTAssertEqual("\(addressFromPublicKey)", "1AC4gh14wwZPULVPCdxUkgqbtPvC92PQPN")
        XCTAssertEqual("\(addressFromPublicKey.cashaddr)", "bitcoincash:qpjdpjrm5zvp2al5u4uzmp36t9m0ll7gd525rss978")
        
        let addressFromFormattedAddress = try? LegacyAddress("1AC4gh14wwZPULVPCdxUkgqbtPvC92PQPN")
        XCTAssertNotNil(addressFromFormattedAddress)
        XCTAssertEqual("\(addressFromFormattedAddress!)", "1AC4gh14wwZPULVPCdxUkgqbtPvC92PQPN")
        XCTAssertEqual(addressFromFormattedAddress!.cashaddr, "bitcoincash:qpjdpjrm5zvp2al5u4uzmp36t9m0ll7gd525rss978")
    }
    
    func testTestnetLegacyAddress() {
        let privateKey = try! PrivateKey(wif: "92pMamV6jNyEq9pDpY4f6nBy9KpV2cfJT4L5zDUYiGqyQHJfF1K")
        let publicKey = privateKey.publicKey()
        let addressFromPublicKey = publicKey.toLegacy()
        XCTAssertEqual("\(addressFromPublicKey)", "mjNkq5ycsAfY9Vybo9jG8wbkC5mbpo4xgC")
        XCTAssertEqual("\(addressFromPublicKey.cashaddr)", "bchtest:qq498xkl67h0espwqxttfn8hdt4g3g05wqtqeyg993")
        
        let addressFromFormattedAddress = try? LegacyAddress("mjNkq5ycsAfY9Vybo9jG8wbkC5mbpo4xgC")
        XCTAssertNotNil(addressFromFormattedAddress)
        XCTAssertEqual("\(addressFromFormattedAddress!)", "mjNkq5ycsAfY9Vybo9jG8wbkC5mbpo4xgC")
        XCTAssertEqual(addressFromFormattedAddress!.cashaddr, "bchtest:qq498xkl67h0espwqxttfn8hdt4g3g05wqtqeyg993")
    }
    
    func testInvalidChecksumLegacyAddress() {
        do {
            _ = try LegacyAddress("175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W")
            XCTFail("Should throw invalid checksum error.")
        } catch AddressError.invalid {
            // Success
        } catch {
            XCTFail("Should throw invalid checksum error.")
        }
    }
    
    func testMainnetCashaddr() {
        let privateKey = try! PrivateKey(wif: "5K6EwEiKWKNnWGYwbNtrXjA8KKNntvxNKvepNqNeeLpfW7FSG1v")
        let publicKey = privateKey.publicKey()
        let addressFromPublicKey = publicKey.toCashaddr()
        XCTAssertEqual("\(addressFromPublicKey)", "bitcoincash:qpjdpjrm5zvp2al5u4uzmp36t9m0ll7gd525rss978")
        
        let addressFromFormattedAddress = try? Cashaddr("bitcoincash:qpjdpjrm5zvp2al5u4uzmp36t9m0ll7gd525rss978")
        XCTAssertNotNil(addressFromFormattedAddress)
        XCTAssertEqual("\(addressFromFormattedAddress!)", "bitcoincash:qpjdpjrm5zvp2al5u4uzmp36t9m0ll7gd525rss978")
    }
    
    func testTestnetCashaddr() {
        let privateKey = try! PrivateKey(wif: "92pMamV6jNyEq9pDpY4f6nBy9KpV2cfJT4L5zDUYiGqyQHJfF1K")
        let publicKey = privateKey.publicKey()
        let addressFromPublicKey = publicKey.toCashaddr()
        XCTAssertEqual("\(addressFromPublicKey)", "bchtest:qq498xkl67h0espwqxttfn8hdt4g3g05wqtqeyg993")
        
        let addressFromFormattedAddress = try? Cashaddr("bchtest:qq498xkl67h0espwqxttfn8hdt4g3g05wqtqeyg993")
        XCTAssertNotNil(addressFromFormattedAddress)
        XCTAssertEqual("\(addressFromFormattedAddress!)", "bchtest:qq498xkl67h0espwqxttfn8hdt4g3g05wqtqeyg993")
    }
    
    func testInvalidChecksumCashaddr() {
        // invalid address
        do {
            _ = try Cashaddr("bitcoincash:qpjdpjrm5zvp2al5u4uzmp36t9m0ll7gd525rss978💦😆")
            XCTFail("Should throw invalid checksum error.")
        } catch AddressError.invalid {
            // Success
        } catch {
            XCTFail("Should throw invalid checksum error.")
        }
        
        // mismatch scheme and address
        do {
            _ = try Cashaddr("bchtest:qpjdpjrm5zvp2al5u4uzmp36t9m0ll7gd525rss978")
            XCTFail("Should throw invalid checksum error.")
        } catch AddressError.invalid {
            // Success
        } catch {
            XCTFail("Should throw invalid checksum error.")
        }
    }
    
    func testWrongNetworkCashaddr() {
        do {
            _ = try Cashaddr("pref:pr6m7j9njldwwzlg9v7v53unlr4jkmx6ey65nvtks5")
            XCTFail("Should throw invalid scheme error.")
        } catch AddressError.invalidScheme {
            // Success
        } catch {
            XCTFail("Should throw wrong network invalid scheme error.")
        }
    }
    
    func testMainnetStealthAddress() {
        let scanPrivateKey = try! PrivateKey(wif: "KwpmnZfQvZxRaB6Bt2HXJhmmC1DFb3tszFG4ciRccxrY6V29iR8h")
        let spendPrivateKey = try! PrivateKey(wif: "L2Y2s2WfTwdfCrtFyPWUTgYAnGTeEsC664rbCoa3m7ZKxWG74nZQ")
        
        let scanPublicKey = scanPrivateKey.publicKey()
        let spendPublicKey = spendPrivateKey.publicKey()
        
        let addressFromScanPublicKey = scanPublicKey.toLegacy()
        XCTAssertEqual("\(addressFromScanPublicKey)", "1HYEeWaMVQgCLWYArSbsSK4ZrvBHMxeVaN")
        
        let addressFromSpendPublicKey = spendPublicKey.toLegacy()
        XCTAssertEqual("\(addressFromSpendPublicKey)", "1HNfWG62FH8hAPbGE5s5WXV3D4a8zWpzvt")
        
        let stealthAddress = StealthAddress(
            scanPublicKey: scanPublicKey,
            spendPublicKey: spendPublicKey,
            network: .mainnet
        )
        XCTAssertEqual("\(stealthAddress)", "vJmvrmc3wGrdoiGsT7HnbbdhSkL9Bb5TmrPZsGWz7nsJx4iC5c1E21Rypy14pEXFk273qg7WMwDvDnyrPzFyP7YVwzz89e86Ww6QPe")
        
        let addressFromStealthAddress = try? StealthAddress(
            "vJmvrmc3wGrdoiGsT7HnbbdhSkL9Bb5TmrPZsGWz7nsJx4iC5c1E21Rypy14pEXFk273qg7WMwDvDnyrPzFyP7YVwzz89e86Ww6QPe"
        )
        XCTAssertNotNil(addressFromStealthAddress)
        XCTAssertEqual("\(addressFromStealthAddress!)", "vJmvrmc3wGrdoiGsT7HnbbdhSkL9Bb5TmrPZsGWz7nsJx4iC5c1E21Rypy14pEXFk273qg7WMwDvDnyrPzFyP7YVwzz89e86Ww6QPe")
    }
    
    func testMainnetXVGStealthAddress() {
        let seed = Mnemonic.seed(mnemonic: [
            "january",
            "february",
            "march",
            "may",
            "june",
            "july",
            "august",
            "september",
            "october",
            "november",
            "december"
            ])
        let hdPrivateKey = HDPrivateKey(seed: seed, network: .mainnetXVG)
        let scanPrivateKey = try! hdPrivateKey
            .derived(at: 47, hardened: true)
            .derived(at: 0, hardened: true)
            .derived(at: 0, hardened: true)
            .derived(at: 0)
        let spendPrivateKey = try! hdPrivateKey
            .derived(at: 47, hardened: true)
            .derived(at: 0, hardened: true)
            .derived(at: 1, hardened: true)
            .derived(at: 0)
        
        print(scanPrivateKey.privateKey().data)
        
        let scanPublicKey = scanPrivateKey.privateKey().publicKey()
        let spendPublicKey = spendPrivateKey.privateKey().publicKey()
        
        let addressFromScanPublicKey = scanPublicKey.toLegacy()
        XCTAssertEqual("\(addressFromScanPublicKey)", "DJ5QbtffmrJr75pFeNcdgQg9SxrYXBprdK")
        
        let addressFromSpendPublicKey = spendPublicKey.toLegacy()
        XCTAssertEqual("\(addressFromSpendPublicKey)", "D6WSnrGEZqWo9qJZ3TGq7CJRDLDdxZabdk")
        
        let stealthAddress = StealthAddress(
            scanPublicKey: scanPublicKey,
            spendPublicKey: spendPublicKey,
            network: .mainnetXVG
        )
        XCTAssertEqual("\(stealthAddress)", "smYnkGT73m5t9KhgSSJoR5JPSB8KfZS5mV1pzHo3M8tCAqoP2bv8V55mDnmHxbxu921cJMo4zPAJnHtYQvuQysLUgkqGX9yafaznzg")
        
        let addressFromStealthAddress = try? StealthAddress(
            "smYnkGT73m5t9KhgSSJoR5JPSB8KfZS5mV1pzHo3M8tCAqoP2bv8V55mDnmHxbxu921cJMo4zPAJnHtYQvuQysLUgkqGX9yafaznzg"
        )
        XCTAssertNotNil(addressFromStealthAddress)
        XCTAssertEqual("\(addressFromStealthAddress!)", "smYnkGT73m5t9KhgSSJoR5JPSB8KfZS5mV1pzHo3M8tCAqoP2bv8V55mDnmHxbxu921cJMo4zPAJnHtYQvuQysLUgkqGX9yafaznzg")
    }
}
