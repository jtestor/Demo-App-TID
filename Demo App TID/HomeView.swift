//
//  HomeView.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var manager: HealthManager
    var body: some View {
        VStack{
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 20), count: 2)){
                ActivityCard()
                ActivityCard()
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    HomeView()
}
