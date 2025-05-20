//
//  HealthManager.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//

import Foundation
import HealthKit

class HealthManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    
    init (){
        let steps = HKQuantityType(.stepCount)
        
        let healthTypes: Set = [steps]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: healthTypes)
            } catch {
                print("error fetching health data")
            }
        }
    }
}
