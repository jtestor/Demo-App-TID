//
//  Demo_App_TIDApp.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//

import SwiftUI

@main
struct Demo_App_TIDApp: App {
    @StateObject var manager = HealthManager()
    
    var body: some Scene {
        WindowGroup {
            HealthTidTabView()
                .environmentObject(manager)
        }
    }
}

