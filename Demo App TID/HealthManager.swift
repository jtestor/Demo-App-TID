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
        @Published var isAuthorized: Bool = false


    
    init (){
        let writeTypes: Set = [
                HKObjectType.quantityType(forIdentifier: .bodyMass)!
            ]

           
            let readTypes: Set = [
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .bodyMass)!
            ]

        
        Task {
            
            do {
                try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
                DispatchQueue.main.async {
                    self.isAuthorized = true
                }
            } catch {
                print("error fetching health data")
            }
        }
    }
    func fetchTodaySteps(){
        let steps = HKQuantityType(.stepCount)
        _ = HKQuantityType(.activeEnergyBurned)
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
    func saveWeight(valueKg: Double, date: Date) {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let type      = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let quantity  = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: valueKg)
        let sample    = HKQuantitySample(type: type,
                                         quantity: quantity,
                                         start: date,
                                         end:   date)

        healthStore.save(sample) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("weight saved in Health-kit")
                    self?.fetchTodayWeight()          // <-- refresco seguro
                } else {
                    print("error saving weight:", error ?? "nil")
                }
            }
        }
    }
    func fetchTodayWeight() {
        let weightType = HKQuantityType(.bodyMass)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: [.init(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, error in
            guard let sample = results?.first as? HKQuantitySample, error == nil else {
                print(" cannot fetch todays weight")
                return
            }

            let value = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            let activity = Activity(id: 2, title: "Today Weight", subtitle: "Goal: 70kg", image: "scalemass", amount: "\(value.formattedString())")

            DispatchQueue.main.async {
                self.activities["todayWeight"] = activity
            }
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
