//
//  KeyManager.swift
//  Demo App TID
//
//  Created by Miguel Testor on 16-06-25.
//

import Foundation
import Security

/// Maneja la clave privada en el Keychain y expone la clave pública en formato PEM.
enum KeyManager {

    // Identificador para ubicar la clave en el Keychain (solo este dispositivo).
    private static let tag = "com.demoapptid.privatekey".data(using: .utf8)!

    /// Genera el par RSA (2048 bits) **solo si aún no existe**.
    static func generateKeyPairIfNeeded() {
        print("KeyManager: ejecutando generateKeyPairIfNeeded()")
        guard privateKey() == nil else {
            print("ya existe una clave privada en el keychain")
            return }   // ya existen
        
        let privateKeyAttrs: [String: Any] = [
               kSecAttrIsPermanent     as String: true,
               kSecAttrApplicationTag  as String: tag,
               kSecAttrAccessible      as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
           ]

           let attributes: [String: Any] = [
               kSecAttrKeyType         as String: kSecAttrKeyTypeRSA,
               kSecAttrKeySizeInBits   as String: 2048,
               kSecPrivateKeyAttrs     as String: privateKeyAttrs
           ]
        var error : Unmanaged<CFError>?
        if #available(iOS 15.0, *){
            guard let priv = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                print("error creating private key", error!.takeRetainedValue())
                return
            }
            let pub = SecKeyCopyPublicKey(priv)
            print(" claves RSA creadas y guardadas en IOs 15+")
        } else{
            var pub, priv: SecKey?
            let status = SecKeyGeneratePair(attributes as CFDictionary, &pub, &priv)
            if status == errSecSuccess{
                print("Par de claves RSA creado y guardado (API antigua)")
            }else {
                print("error generando claves - status: ", status)
            }
        }
    }

    /// Devuelve la clave privada desde Keychain.
    static func privateKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass               as String: kSecClassKey,
            kSecAttrApplicationTag  as String: tag,
            kSecAttrKeyType         as String: kSecAttrKeyTypeRSA,
            kSecReturnRef           as String: true
        ]
        var item: CFTypeRef?
        return SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess
               ? (item as! SecKey)
               : nil
    }

    /// Exporta la clave **pública** en PEM para entregársela a la Raspberry.
    static func publicKeyPEM() -> String? {
        guard let priv = privateKey(),
              let pub = SecKeyCopyPublicKey(priv),
              let data = SecKeyCopyExternalRepresentation(pub, nil) as Data? else { return nil }

        // Cabecera PEM
        let b64 = data.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
        return """
        -----BEGIN PUBLIC KEY-----
        \(b64)
        -----END PUBLIC KEY-----
        """
    }
    //  Desencripta la clave AES cifrada con tu clave pública (RSA-OAEP-SHA256)
    static func decryptAESKey(_ encrypted: Data) -> Data? {
        guard let priv = privateKey() else { return nil }
        var error: Unmanaged<CFError>?
        let clear = SecKeyCreateDecryptedData(
            priv,
            .rsaEncryptionOAEPSHA256,
            encrypted as CFData,
            &error
        )
        if clear == nil {
            print("Error RSA decrypt:", error?.takeRetainedValue().localizedDescription ?? "unknown")
        }
        return clear as Data?
    }

}
