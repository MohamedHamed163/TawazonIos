//
//  APIResponseModels.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation

// MARK: - Pagination
struct PageResponse<T: Decodable>: Decodable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let last: Bool
}

// MARK: - User Models
struct UserProfileResponse: Decodable {
    let id: String
    let email: String
    let fullName: String
    let role: String
    let height: Double?
    let weight: Double?
    let age: Int?
    let gender: String?
    let fitnessGoal: String?
    let avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?
}

struct UpdateProfileRequest: Encodable {
    let fullName: String?
    let height: Double?
    let weight: Double?
    let age: Int?
    let gender: String?
    let fitnessGoal: String?
    let avatarUrl: String?
}

struct ProgressLogRequest: Encodable {
    let weight: Double
    let bodyFatPercentage: Double?
    let notes: String?
    let logDate: String // ISO date format
}

struct ProgressLogResponse: Decodable {
    let id: String
    let weight: Double
    let bodyFatPercentage: Double?
    let notes: String?
    let logDate: String
    let createdAt: String
}

// MARK: - Coach Models
struct CoachProfileResponse: Decodable {
    let id: String
    let userId: String
    let bio: String?
    let certifications: [String]
    let specialties: [String]
    let verificationStatus: String
    let rating: Double?
    let ratingCount: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct CreateCoachProfileRequest: Encodable {
    let bio: String
    let certifications: [String]
    let specialties: [String]
}

struct UpdateCoachProfileRequest: Encodable {
    let bio: String?
    let certifications: [String]?
    let specialties: [String]?
}

// MARK: - Program Models
struct ProgramResponse: Decodable {
    let id: String
    let coachProfileId: String
    let name: String
    let description: String?
    let durationWeeks: Int
    let difficulty: String
    let workouts: [WorkoutResponse]
    let dietPlans: [DietPlanResponse]
    let createdAt: String?
    let updatedAt: String?
}

struct WorkoutResponse: Decodable {
    let id: String
    let name: String
    let description: String?
    let dayOfWeek: Int
    let orderIndex: Int
}

struct DietPlanResponse: Decodable {
    let id: String
    let name: String
    let description: String?
    let targetCalories: Int?
}

// MARK: - Video Models
struct VideoMetadataResponse: Decodable {
    let id: String
    let title: String
    let description: String?
    let streamUrl: String
    let thumbnailUrl: String?
    let contentType: String?
    let sizeBytes: Int64?
    let duration: Int?
    let difficulty: String?
    let equipmentTags: [String]
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, streamUrl, thumbnailUrl
        case contentType, sizeBytes, duration, difficulty, equipmentTags, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        streamUrl = try c.decode(String.self, forKey: .streamUrl)
        thumbnailUrl = try c.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        contentType = try c.decodeIfPresent(String.self, forKey: .contentType)
        sizeBytes = try c.decodeIfPresent(Int64.self, forKey: .sizeBytes)
        duration = try c.decodeIfPresent(Int.self, forKey: .duration)
        difficulty = try c.decodeIfPresent(String.self, forKey: .difficulty)
        equipmentTags = try c.decodeIfPresent([String].self, forKey: .equipmentTags) ?? []
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

// MARK: - Subscription Models
struct SubscriptionResponse: Decodable {
    let id: String
    let userId: String
    let coachProfileId: String
    let status: String
    let startDate: String
    let endDate: String
    let createdAt: String?
}

struct CreateSubscriptionRequest: Encodable {
    let coachProfileId: String
    let startDate: String // ISO date format
    let endDate: String // ISO date format
}

// MARK: - Nutrition Models
struct FoodSearchResponse: Decodable {
    let fdcId: Int
    let name: String
    let nameAr: String?
    let category: String?
    let categoryAr: String?
    let imageUrl: String?
}

struct FoodDetailResponse: Decodable {
    let fdcId: Int
    let name: String
    let nameAr: String?
    let imageUrl: String?
    let category: String?
    let categoryAr: String?
    let servingBasis: String
    let macros: MacrosResponse
    let vitaminsAndMinerals: [VitaminMineralInfo]
    let portions: [PortionInfo]
}

struct MacrosResponse: Decodable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let saturatedFat: Double?
    let transFat: Double?
    let cholesterol: Double?
}

struct VitaminMineralInfo: Decodable {
    let name: String
    let amount: Double
    let unit: String
}

struct PortionInfo: Decodable {
    let amount: Double
    let unit: String
    let description: String
    let gramWeight: Double
}

struct FoodCategoryResponse: Decodable {
    let id: Int
    let name: String
    let nameAr: String?
    let description: String?
}

// MARK: - Storage Models
struct PresignedUploadRequest: Encodable {
    let filename: String
    let contentType: String
}

struct PresignedUploadResponse: Decodable {
    let uploadUrl: String
    let storageKey: String
    let expiresInSeconds: Int
}

// MARK: - Video Create Models
struct CreateVideoMetadataRequest: Encodable {
    let coachProfileId: String
    let title: String
    let description: String?
    let storageKey: String
    let duration: Int
    let difficulty: String
    let equipmentTags: [String]?
    let thumbnailKey: String?
    let contentType: String
    let sizeBytes: Int64
}

// MARK: - Program Create Models
struct CreateProgramRequest: Encodable {
    let coachProfileId: String
    let name: String
    let description: String?
    let durationWeeks: Int
    let difficulty: String
    let workouts: [CreateWorkoutRequest]
    let dietPlans: [CreateDietPlanRequest]
}

struct CreateWorkoutRequest: Encodable {
    let name: String
    let description: String?
    let dayOfWeek: Int
    let orderIndex: Int
}

struct CreateDietPlanRequest: Encodable {
    let name: String
    let description: String?
    let targetCalories: Int?
}

// MARK: - Admin Models
struct VerifyCoachRequest: Encodable {
    let status: String // "VERIFIED" or "REJECTED"
}

struct SuspendUserRequest: Encodable {
    let suspended: Bool
}

// MARK: - Dish Models
struct DishResponse: Decodable {
    let id: String
    let nameEn: String
    let nameAr: String?
    let imageUrl: String?
    let defaultServingGrams: Double
    let caloriesPerServing: Double
    let proteinPerServing: Double
    let carbsPerServing: Double
    let fatPerServing: Double
    let ingredients: [DishIngredientResponse]
    let createdAt: String?
    let updatedAt: String?
}

struct DishSearchResponse: Decodable {
    let id: String
    let nameEn: String
    let nameAr: String?
    let imageUrl: String?
    let caloriesPerServing: Double
}

struct CreateDishRequest: Encodable {
    let nameEn: String
    let nameAr: String?
    let imageUrl: String?
    let defaultServingGrams: Double
    let ingredients: [DishIngredientRequest]
}

struct UpdateDishRequest: Encodable {
    let nameEn: String?
    let nameAr: String?
    let imageUrl: String?
    let defaultServingGrams: Double?
    let ingredients: [DishIngredientRequest]?
}

struct DishIngredientRequest: Encodable {
    let ingredientFdcId: Int
    let quantityGrams: Double
}

struct DishIngredientResponse: Decodable {
    let id: String
    let ingredientFdcId: Int
    let ingredientName: String?
    let quantityGrams: Double
}

// MARK: - Meal Models
struct MealResponse: Decodable {
    let id: String
    let name: String
    let createdBy: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let items: [MealItemResponse]
    let createdAt: String?
    let updatedAt: String?
}

struct CreateMealRequest: Encodable {
    let name: String
    let items: [CreateMealItemRequest]
}

struct CreateMealItemRequest: Encodable {
    let foodType: String // "FOUNDATION", "DISH", or "BRANDED"
    let usdaFdcId: Int?
    let dishId: String?
    let quantity: Double
    let unit: String // "GRAM" or "PIECE"
}

struct MealItemResponse: Decodable {
    let id: String
    let foodType: String
    let usdaFdcId: Int?
    let dishId: String?
    let quantity: Double
    let unit: String
    let foodName: String?
    let macros: MacroResult?
}

struct MacroResult: Decodable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

