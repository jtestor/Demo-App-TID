import Foundation
import Security
import CryptoKit


final class IoTClient {

    private weak var healthManager: HealthManager?

    init(manager: HealthManager) {
        self.healthManager = manager
    }
    

    // Paso 1 – clave AES
    func fetchEncryptedAESKey(from urlString: String,
                              completion: @escaping (Bool) -> Void) {

        guard
            let url = URL(string: urlString),
            let pemKey = KeyManager.publicKeyPEM(),
            let jsonBody = try? JSONEncoder().encode(["public_key": pemKey])
        else {
            print("❌ Error al preparar clave pública PEM para handshake")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonBody
        
        print("➡️  URL:", url)
        print("➡️  Método:", request.httpMethod ?? "")
        if let body = request.httpBody,
           let bodyStr = String(data: body, encoding: .utf8) {
            print("➡️  Body:\n", bodyStr)
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let http = response as? HTTPURLResponse {
                print("🌐 HTTP status:", http.statusCode)
            }
            if let error = error {
                print(" Error HTTP AES:", error)
                completion(false)
                return
            }

            guard
                let data = data,
                let rawJSON = String(data: data, encoding: .utf8)
            else {
                print(" Respuesta vacía / binaria (AES)")
                completion(false)
                return
            }

            print("🔸 RAW /handshake:", rawJSON)

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                let encryptedB64 = json["clave_aes"],
                let encryptedKey = Data(base64Encoded: encryptedB64)
            else {
                print("❌ JSON /handshake sin 'clave_aes'")
                completion(false)
                return
            }

            print("🔐 Recibida clave AES cifrada (\(encryptedKey.count) bytes)")

            guard let aesKeyData = KeyManager.decryptAESKey(encryptedKey) else {
                print("❌ RSA decrypt falló (clave AES)")
                completion(false)
                return
            }

            AESKeyManager.shared.setKey(aesKeyData)
            print("✅ AES Key almacenada (\(aesKeyData.count) bytes)")
            completion(true)
        }.resume()
        print("🟢 dataTask.resume() ejecutado")
    }

    
    // MARK: -  Handshake publico
    func startHandshake(baseURL: String) {
        fetchEncryptedAESKey(from: "\(baseURL)/handshake") { [weak self] ok in
            guard ok else { print("❌ Handshake fallido"); return }
            self?.fetchEncryptedPayload(from: "\(baseURL)/telemetria")
        }
    }
    // Paso 2 – payload cifrado
    func fetchEncryptedPayload(from urlString: String) {

        guard let url = URL(string: urlString) else {
            print("❌ URL inválida (payload): \(urlString)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Error HTTP payload:", error)
                return
            }

            guard
                let data = data,
                let rawJSON = String(data: data, encoding: .utf8) else {
                print("❌ Respuesta vacía / binaria (payload)")
                return
            }

            print("🔸 RAW /telemetria:", rawJSON)

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                let payloadB64 = json["data"],
                let payload   = Data(base64Encoded: payloadB64)
            else {
                print("❌ JSON /telemetria sin 'data'")
                return
            }

            print("📦 Payload cifrado recibido (\(payload.count) bytes)")

            guard let clear = AESKeyManager.shared.decrypt(payload) else {
                print("❌ Fallo AES-GCM decrypt (payload)")
                return
            }

            guard
                let obj   = try? JSONSerialization.jsonObject(with: clear) as? [String: Any],
                let type  = obj["type"]  as? String,
                let value = obj["value"] as? Double
            else {
                print("❌ JSON desencriptado inválido")
                return
            }

            print("✅ Payload desencriptado:", obj)

            DispatchQueue.main.async {
                if type == "weight" {
                    self.healthManager?.saveWeight(valueKg: value, date: Date())
                } else {
                    print("ℹ️ Tipo '\(type)' no soportado aún")
                }
            }
        }.resume()
    }
}

// ---- AESKeyManager ----
class AESKeyManager {
    static let shared = AESKeyManager()
    private var key: SymmetricKey?

    func setKey(_ data: Data) {
        key = SymmetricKey(data: data)
    }

    func decrypt(_ data: Data) -> Data? {
        guard let key = key else { return nil }
        do {
            let sealed = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealed, using: key)
        } catch {
            print("Error AES-GCM:", error)
            return nil
        }
    }
}
