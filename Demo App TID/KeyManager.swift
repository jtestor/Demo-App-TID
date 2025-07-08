//
//  KeyManager.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//
import Foundation
import Security


enum KeyManager {

    //–––––––––––––––– Tag Keychain
    private static let tag = "com.demoapptid.privatekey".data(using: .utf8)!


    static func generateKeyPairIfNeeded() {
        guard privateKey() == nil else { return } 

        let privAttrs: [String: Any] = [
            kSecAttrIsPermanent     as String: true,
            kSecAttrApplicationTag  as String: tag,
            kSecAttrAccessible      as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let attrs: [String: Any] = [
            kSecAttrKeyType       as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs   as String: privAttrs
        ]

        _ = SecKeyCreateRandomKey(attrs as CFDictionary, nil)
    }


    private static func privateKey() -> SecKey? {
        let q: [String: Any] = [
            kSecClass              as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType        as String: kSecAttrKeyTypeRSA,
            kSecReturnRef          as String: true
        ]
        var item: CFTypeRef?
        return SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess ? (item as! SecKey) : nil
    }


    private static func asn1Len(_ n: Int) -> [UInt8] {
        if n < 128 { return [UInt8(n)] }
        var len = n, out: [UInt8] = []
        while len > 0 { out.insert(UInt8(len & 0xFF), at: 0); len >>= 8 }
        return [0x80 | UInt8(out.count)] + out
    }


    static func publicKeyPEM_PKIX() -> String? {
        guard let priv = privateKey(),
              let pub  = SecKeyCopyPublicKey(priv),
              let pkcs1 = SecKeyCopyExternalRepresentation(pub, nil) as Data? else { return nil }

   
        let algId: [UInt8] = [
            0x30, 0x0D,
            0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01,
            0x05, 0x00
        ]
        let bitStr  = [0x00] + [UInt8](pkcs1)                       
        let bitSeq  = [0x03] + asn1Len(bitStr.count) + bitStr
        let spkiSeq = [0x30] + asn1Len(algId.count + bitSeq.count) + algId + bitSeq

        let b64 = Data(spkiSeq)
            .base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])

        return """
        -----BEGIN PUBLIC KEY-----
        \(b64)
        -----END PUBLIC KEY-----
        """
    }

    // MARK: - Descifrar AES (RSA-OAEP-SHA256)
    static func decryptAESKey(_ encrypted: Data) -> Data? {
        guard let priv = privateKey() else { return nil }
        return SecKeyCreateDecryptedData(priv,
                                         .rsaEncryptionOAEPSHA256,
                                         encrypted as CFData,
                                         nil) as Data?
    }
}
