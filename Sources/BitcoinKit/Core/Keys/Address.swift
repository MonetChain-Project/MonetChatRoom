//
//  Address.swift
//
//  Copyright © 2018 Kishikawa Katsumi
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

import Foundation

public protocol AddressProtocol {
    var network: Network { get }
    var type: AddressType { get }
    var data: Data { get }
    var publicKey: Data? { get }

    var base58: String { get }
    var cashaddr: String { get }
}

#if os(iOS) || os(tvOS) || os(watchOS)
public typealias Address = AddressProtocol & QRCodeConvertible
#else
public typealias Address = AddressProtocol
#endif

public enum AddressError: Error {
    case invalid
    case invalidScheme
    case invalidVersionByte
}

public struct LegacyAddress: Address {
    public let network: Network
    public let type: AddressType
    public let data: Data
    public let base58: Base58Check
    public let cashaddr: String
    public let publicKey: Data?

    public typealias Base58Check = String

    public init(data: Data, type: AddressType, network: Network, base58: String, bech32: String, publicKey: Data?) {
        self.data = data
        self.type = type
        self.network = network
        self.base58 = base58
        self.cashaddr = bech32
        self.publicKey = publicKey
    }

    public init(_ base58: Base58Check) throws {
        guard let raw = Base58.decode(base58) else {
            throw AddressError.invalid
        }
        let checksum = raw.suffix(4)
        let pubKeyHash = raw.dropLast(4)
        let checksumConfirm = Crypto.sha256sha256(pubKeyHash).prefix(4)
        guard checksum == checksumConfirm else {
            throw AddressError.invalid
        }

        let network: Network
        let type: AddressType
        let addressPrefix = pubKeyHash[0]
        switch addressPrefix {
        case Network.mainnet.pubkeyhash:
            network = .mainnet
            type = .pubkeyHash
        case Network.testnet.pubkeyhash:
            network = .testnet
            type = .pubkeyHash
        case Network.mainnet.scripthash:
            network = .mainnet
            type = .scriptHash
        case Network.testnet.scripthash:
            network = .testnet
            type = .scriptHash
        case Network.mainnetXVG.pubkeyhash:
            network = .mainnet
            type = .pubkeyHash
        case Network.mainnetXVG.scripthash:
            network = .mainnet
            type = .scriptHash
        default:
            throw AddressError.invalidVersionByte
        }

        self.network = network
        self.type = type
        self.publicKey = nil
        self.data = pubKeyHash.dropFirst()
        self.base58 = base58

        // cashaddr
        switch type {
        case .pubkeyHash, .scriptHash:
            let payload = Data([type.versionByte160]) + self.data
            self.cashaddr = Bech32.encode(payload, prefix: network.scheme)
        default:
            self.cashaddr = ""
        }
    }
    public init(data: Data, type: AddressType, network: Network) {
        let addressData: Data = [type.versionByte] + data
        self.data = data
        self.type = type
        self.network = network
        self.publicKey = nil
        self.base58 = publicKeyHashToAddress(addressData)
        self.cashaddr = Bech32.encode(addressData, prefix: network.scheme)
    }
}

extension LegacyAddress: Equatable {
    public static func == (lhs: LegacyAddress, rhs: LegacyAddress) -> Bool {
        return lhs.network == rhs.network && lhs.data == rhs.data && lhs.type == rhs.type
    }
}

extension LegacyAddress: CustomStringConvertible {
    public var description: String {
        return base58
    }
}

public struct Cashaddr: Address {
    public let network: Network
    public let type: AddressType
    public let data: Data
    public let base58: String
    public let cashaddr: CashaddrWithScheme
    public let publicKey: Data?

    public typealias CashaddrWithScheme = String

    public init(data: Data, type: AddressType, network: Network, base58: String, bech32: CashaddrWithScheme, publicKey: Data?) {
        self.data = data
        self.type = type
        self.network = network
        self.base58 = base58
        self.cashaddr = bech32
        self.publicKey = publicKey
    }

    public init(_ cashaddr: CashaddrWithScheme) throws {
        guard let decoded = Bech32.decode(cashaddr) else {
            throw AddressError.invalid
        }
        let (prefix, raw) = (decoded.prefix, decoded.data)
        self.cashaddr = cashaddr
        self.publicKey = nil

        switch prefix {
        case Network.mainnet.scheme:
            network = .mainnet
        case Network.testnet.scheme:
            network = .testnet
        case Network.mainnetXVG.scheme:
            network = .mainnetXVG
        default:
            throw AddressError.invalidScheme
        }

        let versionByte = raw[0]
        let hash = raw.dropFirst()

        guard hash.count == VersionByte.getSize(from: versionByte) else {
            throw AddressError.invalidVersionByte
        }
        self.data = hash
        guard let typeBits = VersionByte.TypeBits(rawValue: (versionByte & 0b01111000)) else {
            throw AddressError.invalidVersionByte
        }

        switch typeBits {
        case .pubkeyHash:
            type = .pubkeyHash
            base58 = publicKeyHashToAddress(Data([network.pubkeyhash]) + data)
        case .scriptHash:
            type = .scriptHash
            base58 = publicKeyHashToAddress(Data([network.scripthash]) + data)
        }
    }
    public init(data: Data, type: AddressType, network: Network) {
        let addressData: Data = [type.versionByte] + data
        self.data = data
        self.type = type
        self.network = network
        self.publicKey = nil
        self.base58 = publicKeyHashToAddress(addressData)
        self.cashaddr = Bech32.encode(addressData, prefix: network.scheme)
    }
}

extension Cashaddr: Equatable {
    public static func == (lhs: Cashaddr, rhs: Cashaddr) -> Bool {
        return lhs.network == rhs.network && lhs.data == rhs.data && lhs.type == rhs.type
    }
}

extension Cashaddr: CustomStringConvertible {
    public var description: String {
        return cashaddr
    }
}

public struct StealthAddress: Address {

    public var network: Network
    public var type: AddressType
    public var data: Data
    public var publicKey: Data?
    public var base58: String
    public var cashaddr: String = ""

    public typealias Base58Check = String

    public let scanPublicKey: Data
    public let spendPublicKey: Data

    public init(scanPublicKey: PublicKey, spendPublicKey: PublicKey, network: Network) {
        var addressData = Data()
        // Version
        addressData.append(network.stealthVersion)
        // Options
        addressData.append(0)
        // Scan key
        addressData.append(scanPublicKey.data)
        // Number of scan keys
        addressData.append(1)
        // Spend key
        addressData.append(spendPublicKey.data)
        // Number of sign keys
        addressData.append(1)
        // Prefix length
        addressData.append(0)

        self.network = network
        self.type = AddressType.stealthHash
        self.data = addressData
        self.base58 = publicKeyHashToAddress(addressData)

        self.scanPublicKey = scanPublicKey.data
        self.spendPublicKey = spendPublicKey.data
    }

    public init(_ base58: Base58Check) throws {
        guard let raw = Base58.decode(base58) else {
            throw AddressError.invalid
        }

        let checksum = raw.suffix(4)
        let stealthHash = raw.dropLast(4)
        let checksumConfirm = Crypto.sha256sha256(stealthHash).prefix(4)
        guard checksum == checksumConfirm else {
            throw AddressError.invalid
        }

        let network: Network
        let type: AddressType
        let addressPrefix = stealthHash[0]
        switch addressPrefix {
        case Network.mainnet.stealthVersion:
            network = .mainnet
            type = .stealthHash
        case Network.testnet.stealthVersion:
            network = .testnet
            type = .stealthHash
        case Network.mainnetXVG.stealthVersion:
            network = .mainnetXVG
            type = .stealthHash
        default:
            throw AddressError.invalidVersionByte
        }

        self.scanPublicKey = stealthHash.dropFirst(2).dropLast(36)
        self.spendPublicKey = stealthHash.dropFirst(36).dropLast(2)

        self.network = network
        self.type = type
        self.publicKey = nil
        self.data = stealthHash
        self.base58 = base58
    }

}

extension StealthAddress: CustomStringConvertible {
    public var description: String {
        return base58
    }
}
