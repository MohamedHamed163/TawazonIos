//
//  HealthKitService.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation
import HealthKit
import Combine

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    // Health data types we want to read
    private let readTypes: Set<HKObjectType> = {
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
              let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
              let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let bodyFatPercentage = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
              let leanBodyMass = HKObjectType.quantityType(forIdentifier: .leanBodyMass),
              let height = HKObjectType.quantityType(forIdentifier: .height),
              let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
              let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
            return []
        }
        
        return [
            stepCount,
            heartRate,
            activeEnergyBurned,
            distanceWalkingRunning,
            bodyMass,
            bodyFatPercentage,
            leanBodyMass,
            height,
            dateOfBirth,
            biologicalSex
        ]
    }()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    private init() {
        // Only check authorization if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            checkAuthorizationStatus()
        } else {
            isAuthorized = false
            authorizationStatus = .notDetermined
        }
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // Check if HealthKit entitlement is available
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            // Handle missing entitlement gracefully
            if let nsError = error as NSError?, nsError.domain == "com.apple.healthkit" {
                throw HealthKitError.notAvailable
            }
            throw error
        }
        
        await MainActor.run {
            checkAuthorizationStatus()
        }
    }
    
    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            isAuthorized = false
            authorizationStatus = .notDetermined
            return
        }
        
        let status = healthStore.authorizationStatus(for: stepCount)
        authorizationStatus = status
        isAuthorized = status == .sharingAuthorized
    }
    
    // MARK: - Get Steps
    func getStepsCount(startDate: Date, endDate: Date) async throws -> Double {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = sum.doubleValue(for: HKUnit.count())
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Get Heart Rate
    func getHeartRate(startDate: Date, endDate: Date) async throws -> [HeartRateSample] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let heartRates = samples.map { sample in
                    HeartRateSample(
                        value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
                        date: sample.startDate
                    )
                }
                
                continuation.resume(returning: heartRates)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Get Active Energy Burned
    func getActiveEnergyBurned(startDate: Date, endDate: Date) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Get Distance Walking/Running
    func getDistanceWalkingRunning(startDate: Date, endDate: Date) async throws -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let distance = sum.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                continuation.resume(returning: distance)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Get Body Mass (Weight)
    func getBodyMass() async throws -> Double? {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidType
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Get Body Fat Percentage
    func getBodyFatPercentage() async throws -> Double? {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            throw HealthKitError.invalidType
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyFatType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let bodyFat = sample.quantity.doubleValue(for: HKUnit.percent())
                continuation.resume(returning: bodyFat * 100) // Convert to percentage
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Get Today's Summary
    func getTodaySummary() async throws -> HealthSummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        async let steps = getStepsCount(startDate: startOfDay, endDate: endOfDay)
        async let calories = getActiveEnergyBurned(startDate: startOfDay, endDate: endOfDay)
        async let distance = getDistanceWalkingRunning(startDate: startOfDay, endDate: endOfDay)
        async let heartRates = getHeartRate(startDate: startOfDay, endDate: endOfDay)
        
        let (stepsValue, caloriesValue, distanceValue, heartRatesValue) = try await (steps, calories, distance, heartRates)
        
        let avgHeartRate = heartRatesValue.isEmpty ? nil : heartRatesValue.map { $0.value }.reduce(0, +) / Double(heartRatesValue.count)
        
        return HealthSummary(
            steps: Int(stepsValue),
            calories: Int(caloriesValue),
            distance: distanceValue,
            averageHeartRate: avgHeartRate != nil ? Int(avgHeartRate!) : nil
        )
    }
}

// MARK: - Models
struct HeartRateSample {
    let value: Double
    let date: Date
}

struct HealthSummary {
    let steps: Int
    let calories: Int
    let distance: Double // in kilometers
    let averageHeartRate: Int?
}

// MARK: - Errors
enum HealthKitError: LocalizedError {
    case notAvailable
    case invalidType
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .invalidType:
            return "Invalid health data type"
        case .authorizationDenied:
            return "Health data access was denied"
        }
    }
}

