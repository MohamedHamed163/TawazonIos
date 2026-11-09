# Tawazon iOS API Integration Guide

This document lists all API endpoints integrated in the iOS app and how to use them.

## ✅ All APIs Integrated

### 🔐 Authentication (`/api/v1/auth`) - Public

| Method | Endpoint | Function | Status |
|--------|----------|----------|--------|
| POST | `/auth/register` | `APIService.register()` | ✅ |
| POST | `/auth/login` | `APIService.login()` | ✅ |
| POST | `/auth/refresh` | `APIService.refreshToken()` | ✅ |

**Usage:**
```swift
// Register
let registerRequest = RegisterRequest(
    email: "user@example.com",
    password: "password123",
    fullName: "John Doe",
    role: "USER"
)
let authResponse = try await APIService.shared.register(registerRequest)

// Login
let loginRequest = LoginRequest(email: "user@example.com", password: "password123")
let authResponse = try await APIService.shared.login(loginRequest)
```

---

### 👤 Users (`/api/v1/users`) - Authenticated

| Method | Endpoint | Function | Status |
|--------|----------|----------|--------|
| GET | `/users/me` | `APIService.getUserProfile(token:)` | ✅ |
| PUT | `/users/me` | `APIService.updateUserProfile(_:token:)` | ✅ |
| POST | `/users/me/progress` | `APIService.logProgress(_:token:)` | ✅ |
| GET | `/users/me/progress` | `APIService.getProgressHistory(page:size:token:)` | ✅ |

**Usage:**
```swift
// Get profile
let profile = try await APIService.shared.getUserProfile(token: accessToken)

// Update profile
let updateRequest = UpdateProfileRequest(
    fullName: "John Doe",
    height: 180.5,
    weight: 75.0,
    age: 28,
    gender: "MALE",
    fitnessGoal: "BUILD_MUSCLE"
)
let updatedProfile = try await APIService.shared.updateUserProfile(updateRequest, token: accessToken)

// Log progress
let progressRequest = ProgressLogRequest(
    weight: 74.5,
    bodyFatPercentage: 15.2,
    notes: "Feeling strong",
    logDate: "2025-01-15" // ISO format
)
let progress = try await APIService.shared.logProgress(progressRequest, token: accessToken)
```

---

### 👨‍🏫 Coaches (`/api/v1/coaches`)

| Method | Endpoint | Function | Auth | Status |
|--------|----------|----------|------|--------|
| GET | `/coaches` | `APIService.getCoaches(page:size:)` | Public | ✅ |
| GET | `/coaches/{id}` | `APIService.getCoach(id:)` | Public | ✅ |
| POST | `/coaches` | `APIService.createCoachProfile(_:token:)` | COACH | ✅ |
| PUT | `/coaches/{id}` | `APIService.updateCoachProfile(id:_:token:)` | COACH | ✅ |

**Usage:**
```swift
// List coaches
let coachesPage = try await APIService.shared.getCoaches(page: 0, size: 20)

// Get coach by ID
let coach = try await APIService.shared.getCoach(id: "coach-uuid")

// Create coach profile (COACH role)
let createRequest = CreateCoachProfileRequest(
    bio: "Certified trainer",
    certifications: ["NASM-CPT"],
    specialties: ["STRENGTH", "CARDIO"]
)
let coachProfile = try await APIService.shared.createCoachProfile(createRequest, token: accessToken)

// Update coach profile (COACH role)
let updateRequest = UpdateCoachProfileRequest(
    bio: "Updated bio",
    certifications: ["NASM-CPT", "ACE"],
    specialties: ["STRENGTH"]
)
let updated = try await APIService.shared.updateCoachProfile(id: "coach-uuid", updateRequest, token: accessToken)
```

---

### 📹 Content - Videos (`/api/v1/content/videos`)

| Method | Endpoint | Function | Auth | Status |
|--------|----------|----------|------|--------|
| GET | `/content/videos` | `APIService.getVideos(page:size:)` | Public | ✅ |
| GET | `/content/videos/{id}` | `APIService.getVideo(id:)` | Public | ✅ |
| POST | `/content/videos` | `APIService.createVideo(_:token:)` | COACH | ✅ |
| DELETE | `/content/videos/{id}` | `APIService.deleteVideo(id:token:)` | COACH/ADMIN | ✅ |

**Usage:**
```swift
// List videos
let videosPage = try await APIService.shared.getVideos(page: 0, size: 20)

// Get video by ID
let video = try await APIService.shared.getVideo(id: "video-uuid")

// Create video (COACH role)
// First, get presigned upload URL (see Storage section)
let videoRequest = CreateVideoMetadataRequest(
    coachProfileId: "coach-uuid",
    title: "Full Body HIIT",
    description: "30-minute workout",
    storageKey: "videos/uploaded-video.mp4", // From presigned upload
    duration: 1800,
    difficulty: "INTERMEDIATE",
    equipmentTags: ["dumbbells", "mat"],
    thumbnailKey: "thumbnails/image.jpg",
    contentType: "video/mp4",
    sizeBytes: 52428800
)
let video = try await APIService.shared.createVideo(videoRequest, token: accessToken)

// Delete video (COACH/ADMIN role)
try await APIService.shared.deleteVideo(id: "video-uuid", token: accessToken)
```

---

### 🏋️ Programs (`/api/v1/programs`)

| Method | Endpoint | Function | Auth | Status |
|--------|----------|----------|------|--------|
| GET | `/programs` | `APIService.getPrograms(page:size:)` | Public | ✅ |
| GET | `/programs/{id}` | `APIService.getProgram(id:)` | Public | ✅ |
| POST | `/programs` | `APIService.createProgram(_:token:)` | COACH | ✅ |
| DELETE | `/programs/{id}` | `APIService.deleteProgram(id:token:)` | COACH/ADMIN | ✅ |

**Usage:**
```swift
// List programs
let programsPage = try await APIService.shared.getPrograms(page: 0, size: 20)

// Get program by ID
let program = try await APIService.shared.getProgram(id: "program-uuid")

// Create program (COACH role)
let programRequest = CreateProgramRequest(
    coachProfileId: "coach-uuid",
    name: "8-Week Strength Builder",
    description: "Progressive overload program",
    durationWeeks: 8,
    difficulty: "INTERMEDIATE",
    workouts: [
        CreateWorkoutRequest(
            name: "Push Day",
            description: "Chest and triceps",
            dayOfWeek: 1,
            orderIndex: 1
        )
    ],
    dietPlans: [
        CreateDietPlanRequest(
            name: "Bulking Plan",
            description: "High protein diet",
            targetCalories: 2800
        )
    ]
)
let program = try await APIService.shared.createProgram(programRequest, token: accessToken)

// Delete program (COACH/ADMIN role)
try await APIService.shared.deleteProgram(id: "program-uuid", token: accessToken)
```

---

### 📋 Subscriptions (`/api/v1/subscriptions`) - Authenticated

| Method | Endpoint | Function | Status |
|--------|----------|----------|--------|
| GET | `/subscriptions` | `APIService.getSubscriptions(page:size:token:)` | ✅ |
| POST | `/subscriptions` | `APIService.createSubscription(_:token:)` | ✅ |
| PATCH | `/subscriptions/{id}/cancel` | `APIService.cancelSubscription(id:token:)` | ✅ |

**Usage:**
```swift
// List my subscriptions
let subscriptionsPage = try await APIService.shared.getSubscriptions(page: 0, size: 20, token: accessToken)

// Subscribe to coach
let subscriptionRequest = CreateSubscriptionRequest(
    coachProfileId: "coach-uuid",
    startDate: "2025-02-01", // ISO format
    endDate: "2025-05-01"    // ISO format
)
let subscription = try await APIService.shared.createSubscription(subscriptionRequest, token: accessToken)

// Cancel subscription
let canceled = try await APIService.shared.cancelSubscription(id: "subscription-uuid", token: accessToken)
```

---

### 🍎 Nutrition (`/api/v1/nutrition`) - Public

| Method | Endpoint | Function | Status |
|--------|----------|----------|--------|
| GET | `/nutrition/foods/search` | `APIService.searchFoods(query:page:size:language:)` | ✅ |
| GET | `/nutrition/foods/{fdcId}` | `APIService.getFoodDetail(fdcId:language:)` | ✅ |
| GET | `/nutrition/categories` | `APIService.getFoodCategories(language:)` | ✅ |
| GET | `/nutrition/categories/{id}/foods` | `APIService.getFoodsByCategory(categoryId:page:size:language:)` | ✅ |

**Usage:**
```swift
// Search foods (supports Arabic/English via Accept-Language header)
let foodsPage = try await APIService.shared.searchFoods(
    query: "chicken",
    page: 0,
    size: 20,
    language: "en" // or "ar"
)

// Get food detail
let foodDetail = try await APIService.shared.getFoodDetail(fdcId: 171705, language: "en")

// Get categories
let categories = try await APIService.shared.getFoodCategories(language: "en")

// Get foods by category
let foodsByCategory = try await APIService.shared.getFoodsByCategory(
    categoryId: 1,
    page: 0,
    size: 20,
    language: "en"
)
```

---

### 🍽️ Dishes (`/api/v1/dishes`)

| Method | Endpoint | Function | Auth | Status |
|--------|----------|----------|------|--------|
| GET | `/dishes` | `APIService.getDishes(page:size:)` | Public | ✅ |
| GET | `/dishes/search` | `APIService.searchDishes(query:page:size:)` | Public | ✅ |
| GET | `/dishes/{id}` | `APIService.getDish(id:)` | Public | ✅ |
| POST | `/dishes` | `APIService.createDish(_:token:)` | ADMIN | ✅ |
| PUT | `/dishes/{id}` | `APIService.updateDish(id:_:token:)` | ADMIN | ✅ |
| DELETE | `/dishes/{id}` | `APIService.deleteDish(id:token:)` | ADMIN | ✅ |

**Usage:**
```swift
// List dishes
let dishesPage = try await APIService.shared.getDishes(page: 0, size: 20)

// Search dishes
let searchResults = try await APIService.shared.searchDishes(query: "kebab", page: 0, size: 20)

// Get dish detail
let dish = try await APIService.shared.getDish(id: "dish-uuid")

// Create dish (ADMIN role)
let createRequest = CreateDishRequest(
    nameEn: "Chicken Shawarma",
    nameAr: "شاورما دجاج",
    imageUrl: "https://...",
    defaultServingGrams: 250,
    ingredients: [
        DishIngredientRequest(ingredientFdcId: 171705, quantityGrams: 150),
        DishIngredientRequest(ingredientFdcId: 169738, quantityGrams: 100)
    ]
)
let dish = try await APIService.shared.createDish(createRequest, token: accessToken)

// Update dish (ADMIN role)
let updateRequest = UpdateDishRequest(
    nameEn: "Updated Name",
    defaultServingGrams: 300,
    ingredients: [...]
)
let updated = try await APIService.shared.updateDish(id: "dish-uuid", updateRequest, token: accessToken)

// Delete dish (ADMIN role)
try await APIService.shared.deleteDish(id: "dish-uuid", token: accessToken)
```

---

### 🍲 Meals (`/api/v1/meals`) - COACH Role Required

| Method | Endpoint | Function | Status |
|--------|----------|----------|--------|
| POST | `/meals` | `APIService.createMeal(_:token:)` | ✅ |

**Usage:**
```swift
// Create meal template (COACH role)
let mealRequest = CreateMealRequest(
    name: "High Protein Lunch",
    items: [
        CreateMealItemRequest(
            foodType: "FOUNDATION",
            usdaFdcId: 171705,
            dishId: nil,
            quantity: 200,
            unit: "GRAM"
        ),
        CreateMealItemRequest(
            foodType: "DISH",
            usdaFdcId: nil,
            dishId: "dish-uuid",
            quantity: 1,
            unit: "PIECE"
        )
    ]
)
let meal = try await APIService.shared.createMeal(mealRequest, token: accessToken)
```

---

### 📦 Storage (`/api/v1/storage`) - COACH Role Required

| Method | Endpoint | Function | Status |
|--------|----------|----------|--------|
| POST | `/storage/presigned-upload` | `APIService.getPresignedUploadUrl(_:token:)` | ✅ |

**Usage:**
```swift
// Get presigned upload URL (COACH role)
let uploadRequest = PresignedUploadRequest(
    filename: "full-body-hiit.mp4",
    contentType: "video/mp4"
)
let presignedResponse = try await APIService.shared.getPresignedUploadUrl(uploadRequest, token: accessToken)

// Upload file to presigned URL
var uploadRequest = URLRequest(url: URL(string: presignedResponse.uploadUrl)!)
uploadRequest.httpMethod = "PUT"
uploadRequest.setValue(presignedResponse.contentType, forHTTPHeaderField: "Content-Type")
// Set file data as body
uploadRequest.httpBody = videoData

let (_, response) = try await URLSession.shared.data(for: uploadRequest)
// Then use presignedResponse.storageKey when creating video metadata
```

---

### 👨‍💼 Admin (`/api/v1/admin`) - ADMIN Role Required

| Method | Endpoint | Function | Status |
|--------|----------|----------|--------|
| PATCH | `/admin/coaches/{id}/verify` | `APIService.verifyCoach(id:_:token:)` | ✅ |
| PATCH | `/admin/users/{id}/suspend` | `APIService.suspendUser(id:_:token:)` | ✅ |

**Usage:**
```swift
// Verify coach (ADMIN role)
let verifyRequest = VerifyCoachRequest(status: "VERIFIED") // or "REJECTED"
try await APIService.shared.verifyCoach(id: "coach-uuid", verifyRequest, token: accessToken)

// Suspend user (ADMIN role)
let suspendRequest = SuspendUserRequest(suspended: true)
try await APIService.shared.suspendUser(id: "user-uuid", suspendRequest, token: accessToken)
```

---

## 🔑 Role-Based Access

### USER Role
- ✅ View/update own profile
- ✅ Log progress
- ✅ Subscribe to coaches
- ✅ View all public content (coaches, programs, videos, nutrition, dishes)

### COACH Role
- ✅ All USER abilities
- ✅ Create/update coach profile
- ✅ Create/delete videos
- ✅ Create/delete programs
- ✅ Create meal templates
- ✅ Get presigned upload URLs

### ADMIN Role
- ✅ All COACH abilities
- ✅ Verify/reject coaches
- ✅ Suspend/unsuspend users
- ✅ Create/update/delete dishes

---

## 📝 Notes

1. **Authentication**: All authenticated endpoints require `Bearer {accessToken}` in Authorization header
2. **Language Support**: Nutrition endpoints support `Accept-Language` header (`en` or `ar`)
3. **Pagination**: List endpoints support `page` and `size` parameters (default: page=0, size=20)
4. **Error Handling**: All endpoints throw `APIError` which should be caught and handled
5. **Date Format**: Use ISO 8601 format for dates (e.g., "2025-01-15")

---

## 🧪 Testing

All endpoints are ready to use. Test them by:
1. Making sure backend is running on `http://63.184.58.88:8080`
2. Using the functions in `APIService.shared`
3. Handling errors appropriately in your views

---

## 📚 Model Files

All request/response models are in:
- `Models/APIResponseModels.swift` - All DTOs
- `Services/APIService.swift` - All endpoint functions

---

**All APIs from the backend documentation are now integrated!** 🎉

