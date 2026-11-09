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
struct CoachCertificationDTO: Decodable {
    let id: String
    let title: String?
    let originalFilename: String?
    let contentType: String?
    let fileSizeBytes: Int?
    let fileUrl: String?
    let createdAt: String?

    var displayName: String { title ?? originalFilename ?? "" }
}

struct CoachProfileResponse: Decodable {
    let id: String
    let userId: String
    let bio: String?
    let certifications: [CoachCertificationDTO]
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
    let dietPlan: DietPlanResponse?
    let createdAt: String?
    let updatedAt: String?
}

struct WorkoutResponse: Decodable {
    let id: String
    let name: String
    let description: String?
    let dayOfWeek: Int
    let orderIndex: Int
    let exercises: [ScheduledWorkoutExercise]?
}

struct DietPlanResponse: Decodable {
    let id: String
    let name: String
    let description: String?
    let targetCalories: Int?
    let meals: [DietPlanMealResponse]?
}

struct DietPlanMealResponse: Decodable, Identifiable {
    let id: String
    let dayOfWeek: Int
    let mealType: String
    let orderIndex: Int
    let meal: MealResponse
}

// MARK: - Video Models
struct VideoMetadataResponse: Decodable {
    let id: String
    let coachProfile: CoachProfileDTO?
    let title: String
    let description: String?
    let streamUrl: String
    let thumbnailUrl: String?
    let contentType: String?
    let sizeBytes: Int64?
    let duration: Int?
    let difficulty: String?
    let equipmentTags: [String]
    let likeCount: Int
    let likedByMe: Bool
    let createdAt: String?

    var coachName: String? { coachProfile?.displayName }

    enum CodingKeys: String, CodingKey {
        case id, coachProfile, title, description, streamUrl, thumbnailUrl
        case contentType, sizeBytes, duration, difficulty, equipmentTags
        case likeCount, likedByMe, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        coachProfile = try c.decodeIfPresent(CoachProfileDTO.self, forKey: .coachProfile)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        streamUrl = try c.decode(String.self, forKey: .streamUrl)
        thumbnailUrl = try c.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        contentType = try c.decodeIfPresent(String.self, forKey: .contentType)
        sizeBytes = try c.decodeIfPresent(Int64.self, forKey: .sizeBytes)
        duration = try c.decodeIfPresent(Int.self, forKey: .duration)
        difficulty = try c.decodeIfPresent(String.self, forKey: .difficulty)
        equipmentTags = try c.decodeIfPresent([String].self, forKey: .equipmentTags) ?? []
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        likedByMe = try c.decodeIfPresent(Bool.self, forKey: .likedByMe) ?? false
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

/// Result of a like/unlike toggle: the video's new total like count and whether the
/// calling user currently likes it.
struct VideoLikeResponse: Decodable {
    let likeCount: Int
    let liked: Bool
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
struct MealResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let createdBy: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let items: [MealItemResponse]?
    let cookingSteps: [CookingStepDTO]?
    let createdAt: String?
    let updatedAt: String?
}

struct CookingStepDTO: Decodable {
    let stepNumber: Int?
    let instructionText: String?
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
    let alternatives: [MealItemAlternative]

    enum CodingKeys: String, CodingKey {
        case id, foodType, usdaFdcId, dishId, quantity, unit, foodName, macros, alternatives
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        foodType = try c.decode(String.self, forKey: .foodType)
        usdaFdcId = try c.decodeIfPresent(Int.self, forKey: .usdaFdcId)
        dishId = try c.decodeIfPresent(String.self, forKey: .dishId)
        quantity = try c.decode(Double.self, forKey: .quantity)
        unit = try c.decode(String.self, forKey: .unit)
        foodName = try c.decodeIfPresent(String.self, forKey: .foodName)
        macros = try c.decodeIfPresent(MacroResult.self, forKey: .macros)
        alternatives = try c.decodeIfPresent([MealItemAlternative].self, forKey: .alternatives) ?? []
    }
}

struct MealItemAlternative: Decodable, Identifiable {
    let id: String
    let foodType: String
    let usdaFdcId: Int?
    let dishId: String?
    let quantity: Double
    let unit: String
    let foodName: String?
    let macros: MacroResult?

    enum CodingKeys: String, CodingKey {
        case id, foodType, usdaFdcId, dishId, quantity, unit, foodName, macros
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        foodType = try c.decode(String.self, forKey: .foodType)
        usdaFdcId = try c.decodeIfPresent(Int.self, forKey: .usdaFdcId)
        dishId = try c.decodeIfPresent(String.self, forKey: .dishId)
        quantity = try c.decode(Double.self, forKey: .quantity)
        unit = try c.decode(String.self, forKey: .unit)
        foodName = try c.decodeIfPresent(String.self, forKey: .foodName)
        macros = try c.decodeIfPresent(MacroResult.self, forKey: .macros)
    }
}

struct MacroResult: Decodable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

// MARK: - Coach (nested user — matches backend / Android CoachProfile)
struct CoachUserDTO: Decodable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
}

struct CoachProfileDTO: Decodable {
    let id: String
    let user: CoachUserDTO?
    let bio: String?
    let certifications: [CoachCertificationDTO]
    let specialties: [String]
    let verificationStatus: String?
    let rating: Double?
    let ratingCount: Int?
    let createdAt: String?

    var displayName: String { user?.fullName ?? "" }
    var avatarUrl: String? { user?.avatarUrl }

    enum CodingKeys: String, CodingKey {
        case id, user, bio, certifications, specialties, verificationStatus, rating, ratingCount, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        user = try c.decodeIfPresent(CoachUserDTO.self, forKey: .user)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        certifications = try c.decodeIfPresent([CoachCertificationDTO].self, forKey: .certifications) ?? []
        specialties = try c.decodeIfPresent([String].self, forKey: .specialties) ?? []
        verificationStatus = try c.decodeIfPresent(String.self, forKey: .verificationStatus)
        rating = try c.decodeIfPresent(Double.self, forKey: .rating)
        ratingCount = try c.decodeIfPresent(Int.self, forKey: .ratingCount)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

// MARK: - Dashboard
struct DashboardResponse: Decodable {
    let user: DashboardUser
    let activeSubscription: DashboardSubscription?
    let todayWorkout: DashboardWorkout?
    let unreadNotifications: Int?
    let latestWeight: Double?
    let pendingHealthUpdate: Bool?
}

struct DashboardUser: Decodable {
    let fullName: String
    let avatarUrl: String?
}

struct DashboardSubscription: Decodable {
    let subscriptionId: String
    let coachName: String
    let coachAvatarUrl: String?
    let planName: String
    let daysRemaining: Int
    let coachProfile: CoachProfileDTO?
}

struct DashboardWorkout: Decodable {
    let workoutId: String
    let name: String
    let exerciseCount: Int
}

// MARK: - Today schedule (programs/today)
struct TodayScheduleResponse: Decodable {
    let programId: String
    let programName: String
    let coachName: String?
    let workoutLogId: String?
    let scheduledDate: String?
    let carriedOver: Bool?
    let todayWorkouts: [ScheduledWorkout]
    let dietPlans: [ScheduledDietPlan]
}

struct ScheduledWorkout: Decodable {
    let id: String?
    let name: String
    let description: String?
    let dayOfWeek: Int
    let orderIndex: Int
    let exercises: [ScheduledWorkoutExercise]

    enum CodingKeys: String, CodingKey {
        case id, name, description, dayOfWeek, orderIndex, exercises
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        dayOfWeek = try c.decode(Int.self, forKey: .dayOfWeek)
        orderIndex = try c.decode(Int.self, forKey: .orderIndex)
        exercises = try c.decodeIfPresent([ScheduledWorkoutExercise].self, forKey: .exercises) ?? []
    }
}

struct ScheduledWorkoutExercise: Decodable {
    let id: String
    let exerciseTemplate: ExerciseTemplateDTO
    let sets: Int
    let reps: Int
    let restSeconds: Int
    let orderIndex: Int
}

struct ExerciseTemplateDTO: Decodable {
    let id: String
    let coachProfileId: String?
    let name: String
    let description: String?
    let videoUrl: String?
    let muscleGroup: String?
    let equipment: String?
    let difficulty: String?
    let createdAt: String?
}

struct ScheduledDietPlan: Decodable, Identifiable {
    let id: String?
    let name: String
    let description: String?
    let targetCalories: Int?
    let meals: [DietPlanMealResponse]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, targetCalories, meals
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        targetCalories = try c.decodeIfPresent(Int.self, forKey: .targetCalories)
        meals = try c.decodeIfPresent([DietPlanMealResponse].self, forKey: .meals)
    }
}

// MARK: - Progress summary
struct ProgressSummary: Decodable {
    let currentWeight: Double?
    let startingWeight: Double?
    let weightChange: Double?
    let latestBodyFat: Double?
    let totalLogs: Int?
    let streakDays: Int?
}

// MARK: - Coach plans
struct CoachPlan: Decodable {
    let id: String
    let coachProfileId: String
    let name: String
    let description: String?
    let durationMonths: Int
    let priceEgp: Double
    let active: Bool?
    let createdAt: String?
}

// MARK: - Health records
struct HealthRecord: Decodable {
    let id: String
    let userId: String?
    let height: Double?
    let weight: Double?
    let age: Int?
    let gender: String?
    let fitnessGoals: String?
    let medicalConditions: String?
    let allergies: String?
    let notesToCoach: String?
    let inbodyReportUrl: String?
    let waistCm: Double?
    let chestCm: Double?
    let leftArmCm: Double?
    let rightArmCm: Double?
    let leftThighCm: Double?
    let rightThighCm: Double?
    let hipsCm: Double?
    let neckCm: Double?
    let progressPhotoUrls: [String]?
    let createdAt: String?
}

struct CreateHealthRecordRequest: Encodable {
    init() {}
    var height: Double?
    var weight: Double?
    var age: Int?
    var gender: String?
    var fitnessGoals: String?
    var medicalConditions: String?
    var allergies: String?
    var notesToCoach: String?
    var inbodyReportUrl: String?
    var waistCm: Double?
    var chestCm: Double?
    var leftArmCm: Double?
    var rightArmCm: Double?
    var leftThighCm: Double?
    var rightThighCm: Double?
    var hipsCm: Double?
    var neckCm: Double?
    var progressPhotoUrls: [String]?
}

// MARK: - Notifications (renamed to avoid clash with Foundation.Notification)
struct AppNotificationDTO: Decodable {
    let id: String
    let type: String
    let title: String
    let message: String
    let read: Bool?
    let referenceId: String?
    let referenceType: String?
    let createdAt: String?
}

// MARK: - Subscription checkout (backend uses planId)
struct SubscriptionCheckoutRequest: Encodable {
    let planId: String
}

struct CheckoutResponse: Decodable {
    let checkoutUrl: String
    let subscriptionId: String
}

struct ToggleAutoRenewRequest: Encodable {
    let autoRenew: Bool
}

struct SubscriptionUserDTO: Decodable {
    let id: String
    let email: String?
    let fullName: String?
}

struct SubscriptionPlanDTO: Decodable {
    let id: String
    let name: String?
    let description: String?
    let durationMonths: Int?
    let priceEgp: Double?
}

struct SubscriptionDetailDTO: Decodable {
    let id: String
    let user: SubscriptionUserDTO?
    let coachProfile: CoachProfileDTO?
    let plan: SubscriptionPlanDTO?
    let status: String
    let amountPaid: Double?
    let autoRenew: Bool?
    let createdAt: String?
}

// MARK: - Messaging / Chat
struct UserConversationDTO: Decodable, Identifiable {
    let id: String
    let coachProfileId: String
    let coachName: String?
    let coachAvatarUrl: String?
    let lastMessage: LastMessageDTO?
    let unreadCount: Int
    let createdAt: String?
}

struct LastMessageDTO: Decodable {
    let content: String?
    let sentAt: String?
    let isRead: Bool?
}

struct MessageDTO: Decodable, Identifiable {
    let id: String
    let conversationId: String?
    let senderId: String?
    let senderType: String
    let content: String?
    let attachments: [MessageAttachmentDTO]?
    let sentAt: String?
    let readAt: String?
}

struct MessageAttachmentDTO: Decodable, Identifiable {
    let id: String
    let type: String
    let url: String
    let fileName: String?
}

struct StartConversationRequestDTO: Encodable {
    let coachProfileId: String
}

struct SendMessageRequestDTO: Encodable {
    let content: String
    let attachments: [SendAttachmentDTO]?
}

struct SendAttachmentDTO: Encodable {
    let type: String
    let storageKey: String
    let fileName: String?
}

