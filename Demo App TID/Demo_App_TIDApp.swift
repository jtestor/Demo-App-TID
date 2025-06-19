import SwiftUI

@main
struct Demo_App_TIDApp: App {

    private let healthManager = HealthManager()
    private let iotClient: IoTClient

    init() {
        print("🚀 App inicializada (antes de KeyManager)")
        KeyManager.generateKeyPairIfNeeded()

        iotClient = IoTClient(manager: healthManager)
        print("⚙️  IoTClient creado")
        if let pem = KeyManager.publicKeyPEM() {
            print("----- CLAVE PÚBLICA PEM -----\n\(pem)")
        }
        let base = "https://tid.ngrok.app"
        print("🔗  Iniciando handshake a \(base)")
        iotClient.startHandshake(baseURL: base)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(healthManager)
        }
    }
}
