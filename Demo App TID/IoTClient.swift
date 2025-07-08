//
//  IoTClient.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//

import Foundation
import CommonCrypto
import CryptoKit

//──────────────────────── IoTClient ───────────────────────
final class IoTClient {
    private weak var manager: HealthManager?
    private let handshakeURL = URL(string: "https://tid.ngrok.app/handshake")!
    private let telemetryURL = URL(string: "https://tid.ngrok.app/telemetria")!
    
    init(manager: HealthManager) { self.manager = manager }
    
   
    func startHandshake() {
        guard let pem = KeyManager.publicKeyPEM_PKIX() else { return }
        
        var req = URLRequest(url: handshakeURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["public_key": pem])
        
        print("  POST /handshake bytes=\(req.httpBody?.count ?? 0)")
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { print(" NET:", err); return }
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            self.handleHandshake(data)
        }.resume()
    }
    
    private func handleHandshake(_ data: Data?) {
        guard
            let data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String:String],
            let b64  = json["clave_aes"],
            let enc  = Data(base64Encoded: b64),
            let aes  = KeyManager.decryptAESKey(enc)
        else { print(" body handshake"); return }
        
        AESKeyManager.shared.setKey(aes)
        print(" AES key OK (\(aes.count) bytes)")
        fetchTelemetry()
    }
    
    
    private func fetchTelemetry() {
        URLSession.shared.dataTask(with: telemetryURL) { data, resp, err in
            if let err = err { print("NET telemetry:", err); return }
            guard (resp as? HTTPURLResponse)?.statusCode == 200, let data else { return }
            
            // cuerpo crudo para inspección
            if let raw = String(data: data, encoding: .utf8) {
                print(" RAW /telemetria:", raw)
            }
            
            guard
                let json  = try? JSONSerialization.jsonObject(with: data) as? [String:String],
                let b64   = json["data"],
                let cipher = Data(base64Encoded: b64)
            else { print(" JSON sin 'data'"); return }
            
            print(" bytes cifrados:", cipher.count)
            
         
            guard let clear = AESKeyManager.shared.decryptCBC(cipher) else {
                print(" AES-CBC decrypt falló"); return
            }
            
            guard
                let obj    = try? JSONSerialization.jsonObject(with: clear) as? [String:Any],
                let type   = obj["type"]  as? String,
                let value  = obj["value"] as? Double
            else { print(" JSON claro inválido"); return }
            
            print("Telemetría:", obj)
            
            if type == "weight" {
                DispatchQueue.main.async {
                    self.manager?.saveWeight(valueKg: value, date: Date())
                    self.manager?.fetchTodayWeight()
                }
            }
        }.resume()
    }
}


final class AESKeyManager {
    static let shared = AESKeyManager()
    private var keyData: Data?
    
    func setKey(_ data: Data) { keyData = data }
    
    
    func decryptCBC(_ combined: Data) -> Data? {
        guard combined.count > 16, let keyData else { return nil }
        
        let iv         = combined.prefix(16)
        let ciphertext = combined.dropFirst(16)
        

        let outCapacity = ciphertext.count + kCCBlockSizeAES128
        var outData     = Data(count: outCapacity)
        var outLen: size_t = 0
        
        let status = outData.withUnsafeMutableBytes { outRaw in
            keyData.withUnsafeBytes      { keyPtr in
            iv.withUnsafeBytes           { ivPtr  in
            ciphertext.withUnsafeBytes   { ctPtr  in
                CCCrypt(CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES128),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, keyData.count,
                        ivPtr.baseAddress,
                        ctPtr.baseAddress, ciphertext.count,
                        outRaw.baseAddress, outCapacity,
                        &outLen)
            }}}
        }
        
        guard status == kCCSuccess else {
            print(" CommonCrypto status:", status); return nil
        }
        outData.removeSubrange(outLen..<outData.count)   
        return outData
    }
}
