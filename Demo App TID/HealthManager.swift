//
//  HealthManager.swift
//  Demo App TID
//
//  Created by Miguel Testor on 19-05-25.
//

import Foundation
import HealthKit

extension Date{
    static var startOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }
}

class HealthManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    @Published var activities: [String : Activity] = [:]
    
    init (){
        let steps = HKQuantityType(.stepCount)
        let calories = HKQuantityType(.activeEnergyBurned)
        
        let healthTypes: Set = [steps, calories]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: healthTypes)
            } catch {
                print("error fetching health data")
            }
        }
    }
    func fetchTodaySteps(){
        let steps = HKQuantityType(.stepCount)
        let calories = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: steps , quantitySamplePredicate: predicate){ _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else{
                print ("error fetching todays steps data")
                return
            }
            let stepCount = quantity.doubleValue(for: .count())
            let activity = Activity(id:0, title: "Today steps", subtitle: " Goal 10.000",image: "figure.walk", amount: "\(stepCount.formattedString())")
            DispatchQueue.main.async{
                self.activities["todaySteps"] = activity
            }
            
            
            
            print(stepCount.formattedString())
        }
        
        healthStore.execute(query)
    }
    
    func fetchTodayCalories(){
        let calories = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: calories , quantitySamplePredicate: predicate){ _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else{
                print ("error fetching todays steps data")
                return
            }
            let caloriesBurned = quantity.doubleValue(for: .kilocalorie())
            let activity = Activity(id:1, title: "Today Calories", subtitle: " Goal 2500",image: "flame", amount: "\(caloriesBurned.formattedString())")
            DispatchQueue.main.async{
                self.activities["todayCalories"] = activity
            }
            
            print(caloriesBurned.formattedString())
            
        }
        healthStore.execute(query)
    }
}

extension Double {
    func formattedString()-> String{
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        
        return numberFormatter.string(from: NSNumber(value:self))!
    }
}
