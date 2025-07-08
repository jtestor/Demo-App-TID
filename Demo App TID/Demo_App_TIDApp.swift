//
//  Demo_App_TIDApp.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//

import SwiftUI
import SwiftyRSA
@main
struct Demo_App_TIDApp: App {

    private let healthManager = HealthManager()
    private let iotClient: IoTClient

    init() {
        print("App inicializada (antes de KeyManager)")
        KeyManager.generateKeyPairIfNeeded()

        iotClient = IoTClient(manager: healthManager)
        print(" IoTClient creado")
        iotClient.startHandshake()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(healthManager)
        }
    }
}
