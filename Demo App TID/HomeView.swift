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
                ForEach(manager.activities.sorted(by:{ $0.value.id < $1.value.id}), id: \.key) {item in
                    ActivityCard(activity: item.value)
                    
                }
            }
            .padding(.horizontal)
        }
        .onAppear{
            manager.fetchTodaySteps()
            manager.fetchTodayCalories()
            manager.fetchTodayWeight()
        }
        .onReceive(manager.$isAuthorized){ granted in
                if granted {
                    manager.saveWeight(valueKg: 72.5, date: Date())
                    manager.fetchTodayWeight()
            }
            
        }
    }
}


struct homeView_previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HealthManager())
    }
    
}
