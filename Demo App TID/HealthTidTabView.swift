//
//  HealthTidTabView.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//

import SwiftUI

struct HealthTidTabView: View {
    
    @EnvironmentObject var manager: HealthManager
    @State var selectedTab = "Home"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag("Home")
                .tabItem {
                    Image(systemName: "house")
                    
                }
                .environmentObject(manager)
            
            ContentView()
                .tag("Content")
                .tabItem {
                    Image(systemName: "person")
                    
                }
        }
    }
}

#Preview {
    HealthTidTabView()
}
