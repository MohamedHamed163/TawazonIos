//
//  APIService.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//
//  Canonical copy: `tawazon/tawazon/Services/APIService.swift` (iOS).
//  Keep this watch target subset in sync when you add endpoints, models, or auth behavior.

import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://api.tawazon-fitness.com/api/v1"
    
    private init() {}
    
    // MARK: - Generic Request Method
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        token: String? = nil,
        language: String? = nil
    ) async throws -> T {
        let fullURL = "\(baseURL)\(endpoint)"
        print("🌐 API Request: \(method) \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL: \(fullURL)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let language = language {
            request.setValue(language, forHTTPHeaderField: "Accept-Language")
        }
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            request.httpBody = try encoder.encode(body)
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 Request body: \(jsonString)")
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response body: \(responseString.prefix(500))")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                // Try to parse error response
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    // Check if there are specific error messages
                    if let errors = errorResponse.errors, !errors.isEmpty {
                        let errorMessage = errors.joined(separator: "\n")
                        print("❌ Server errors: \(errorMessage)")
                        throw APIError.serverError(errorMessage)
                    }
                    let errorMessage = errorResponse.message ?? "Server error"
                    print("❌ Server error: \(errorMessage)")
                    throw APIError.serverError(errorMessage)
                }
                
                // Try to parse as APIResponse with errors
                if let apiErrorResponse = try? JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: data) {
                    if let errors = apiErrorResponse.errors, !errors.isEmpty {
                        let errorMessage = errors.joined(separator: "\n")
                        print("❌ API errors: \(errorMessage)")
                        throw APIError.serverError(errorMessage)
                    }
                    let errorMessage = apiErrorResponse.message ?? "Request failed"
                    print("❌ API error: \(errorMessage)")
                    throw APIError.serverError(errorMessage)
                }
                
                // Fallback to HTTP status code
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // Handle DELETE/PATCH operations that return no body (204 No Content)
            if httpResponse.statusCode == 204 || (data.isEmpty && (method == "DELETE" || method == "PATCH")) {
                // For operations that return no body, we need to handle them specially
                // This will be handled by deleteRequest/patchRequest helper methods
                print("✅ Request successful (204 No Content)")
                // Try to decode as EmptyDeleteResponse if that's what's expected
                if T.self == EmptyDeleteResponse.self {
                    return EmptyDeleteResponse() as! T
                }
                // Otherwise, throw an error for unexpected empty response
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let apiResponse = try? decoder.decode(APIResponse<T>.self, from: data) {
                if apiResponse.success, let data = apiResponse.data {
                    print("✅ Request successful")
                    return data
                } else {
                    let errorMessage = apiResponse.message ?? "Request failed"
                    print("❌ API response indicates failure: \(errorMessage)")
                    throw APIError.serverError(errorMessage)
                }
            }
            
            // If not wrapped in ApiResponse, decode directly
            print("✅ Request successful (direct decode)")
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            print("❌ API Error: \(error)")
            throw error
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Authentication Endpoints
    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        return try await self.request(
            endpoint: "/auth/register",
            method: "POST",
            body: request
        )
    }
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        return try await self.request(
            endpoint: "/auth/login",
            method: "POST",
            body: request
        )
    }
    
    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthResponse {
        return try await self.request(
            endpoint: "/auth/refresh",
            method: "POST",
            body: request
        )
    }
    
    // MARK: - User Endpoints
    func getUserProfile(token: String) async throws -> UserProfileResponse {
        return try await self.request(
            endpoint: "/users/me",
            method: "GET",
            token: token
        )
    }
    
    func updateUserProfile(_ request: UpdateProfileRequest, token: String) async throws -> UserProfileResponse {
        return try await self.request(
            endpoint: "/users/me",
            method: "PUT",
            body: request,
            token: token
        )
    }
    
    func logProgress(_ request: ProgressLogRequest, token: String) async throws -> ProgressLogResponse {
        return try await self.request(
            endpoint: "/users/me/progress",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func getProgressHistory(page: Int = 0, size: Int = 20, token: String) async throws -> PageResponse<ProgressLogResponse> {
        return try await self.request(
            endpoint: "/users/me/progress?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }

    /// Upserts today's Apple Watch / HealthKit stats for the current user.
    /// Idempotent on the backend (keyed by user + date), so double-syncing from phone + watch is harmless.
    @discardableResult
    func syncWearableStats(_ request: WearableStatsRequest, token: String) async throws -> WearableStatsResponse {
        return try await self.request(
            endpoint: "/users/me/wearable-stats",
            method: "POST",
            body: request,
            token: token
        )
    }

    // MARK: - Coaches Endpoints
    func getCoaches(page: Int = 0, size: Int = 20) async throws -> PageResponse<CoachProfileResponse> {
        return try await self.request(
            endpoint: "/coaches?page=\(page)&size=\(size)",
            method: "GET"
        )
    }
    
    func getCoach(id: String) async throws -> CoachProfileResponse {
        return try await self.request(
            endpoint: "/coaches/\(id)",
            method: "GET"
        )
    }
    
    func createCoachProfile(_ request: CreateCoachProfileRequest, token: String) async throws -> CoachProfileResponse {
        return try await self.request(
            endpoint: "/coaches",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func updateCoachProfile(id: String, _ request: UpdateCoachProfileRequest, token: String) async throws -> CoachProfileResponse {
        return try await self.request(
            endpoint: "/coaches/\(id)",
            method: "PUT",
            body: request,
            token: token
        )
    }
    
    // MARK: - Programs Endpoints
    func getPrograms(page: Int = 0, size: Int = 20) async throws -> PageResponse<ProgramResponse> {
        return try await self.request(
            endpoint: "/programs?page=\(page)&size=\(size)",
            method: "GET"
        )
    }
    
    func getProgram(id: String) async throws -> ProgramResponse {
        return try await self.request(
            endpoint: "/programs/\(id)",
            method: "GET"
        )
    }
    
    func createProgram(_ request: CreateProgramRequest, token: String) async throws -> ProgramResponse {
        return try await self.request(
            endpoint: "/programs",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func deleteProgram(id: String, token: String) async throws {
        try await deleteRequest(endpoint: "/programs/\(id)", token: token)
    }
    
    // MARK: - Content/Videos Endpoints
    func getVideos(page: Int = 0, size: Int = 20) async throws -> PageResponse<VideoMetadataResponse> {
        return try await self.request(
            endpoint: "/content/videos?page=\(page)&size=\(size)",
            method: "GET"
        )
    }
    
    func getVideo(id: String) async throws -> VideoMetadataResponse {
        return try await self.request(
            endpoint: "/content/videos/\(id)",
            method: "GET"
        )
    }
    
    func createVideo(_ request: CreateVideoMetadataRequest, token: String) async throws -> VideoMetadataResponse {
        return try await self.request(
            endpoint: "/content/videos",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func deleteVideo(id: String, token: String) async throws {
        try await deleteRequest(endpoint: "/content/videos/\(id)", token: token)
    }
    
    // MARK: - Subscriptions Endpoints
    func getSubscriptions(page: Int = 0, size: Int = 20, token: String) async throws -> PageResponse<SubscriptionResponse> {
        return try await self.request(
            endpoint: "/subscriptions?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }
    
    func createSubscription(_ request: CreateSubscriptionRequest, token: String) async throws -> SubscriptionResponse {
        return try await self.request(
            endpoint: "/subscriptions",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func cancelSubscription(id: String, token: String) async throws -> SubscriptionResponse {
        return try await self.request(
            endpoint: "/subscriptions/\(id)/cancel",
            method: "PATCH",
            token: token
        )
    }
    
    // MARK: - Nutrition Endpoints
    func searchFoods(query: String, page: Int = 0, size: Int = 20, language: String = "en") async throws -> PageResponse<FoodSearchResponse> {
        var endpoint = "/nutrition/foods/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&page=\(page)&size=\(size)"
        return try await self.request(
            endpoint: endpoint,
            method: "GET",
            language: language
        )
    }
    
    func getFoodDetail(fdcId: Int, language: String = "en") async throws -> FoodDetailResponse {
        return try await self.request(
            endpoint: "/nutrition/foods/\(fdcId)",
            method: "GET",
            language: language
        )
    }
    
    func getFoodCategories(language: String = "en") async throws -> [FoodCategoryResponse] {
        return try await self.request(
            endpoint: "/nutrition/categories",
            method: "GET",
            language: language
        )
    }
    
    func getFoodsByCategory(categoryId: Int, page: Int = 0, size: Int = 20, language: String = "en") async throws -> PageResponse<FoodSearchResponse> {
        return try await self.request(
            endpoint: "/nutrition/categories/\(categoryId)/foods?page=\(page)&size=\(size)",
            method: "GET",
            language: language
        )
    }
    
    // MARK: - Storage Endpoints
    func getPresignedUploadUrl(_ request: PresignedUploadRequest, token: String) async throws -> PresignedUploadResponse {
        return try await self.request(
            endpoint: "/storage/presigned-upload",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    // MARK: - Admin Endpoints
    func verifyCoach(id: String, _ request: VerifyCoachRequest, token: String) async throws {
        try await patchRequest(endpoint: "/admin/coaches/\(id)/verify", body: request, token: token)
    }
    
    func suspendUser(id: String, _ request: SuspendUserRequest, token: String) async throws {
        try await patchRequest(endpoint: "/admin/users/\(id)/suspend", body: request, token: token)
    }
    
    // MARK: - Dish Endpoints
    func getDishes(page: Int = 0, size: Int = 20) async throws -> PageResponse<DishSearchResponse> {
        return try await self.request(
            endpoint: "/dishes?page=\(page)&size=\(size)",
            method: "GET"
        )
    }
    
    func searchDishes(query: String, page: Int = 0, size: Int = 20) async throws -> PageResponse<DishSearchResponse> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await self.request(
            endpoint: "/dishes/search?q=\(encodedQuery)&page=\(page)&size=\(size)",
            method: "GET"
        )
    }
    
    func getDish(id: String) async throws -> DishResponse {
        return try await self.request(
            endpoint: "/dishes/\(id)",
            method: "GET"
        )
    }
    
    func createDish(_ request: CreateDishRequest, token: String) async throws -> DishResponse {
        return try await self.request(
            endpoint: "/dishes",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func updateDish(id: String, _ request: UpdateDishRequest, token: String) async throws -> DishResponse {
        return try await self.request(
            endpoint: "/dishes/\(id)",
            method: "PUT",
            body: request,
            token: token
        )
    }
    
    func deleteDish(id: String, token: String) async throws {
        try await deleteRequest(endpoint: "/dishes/\(id)", token: token)
    }
    
    // MARK: - Meal Endpoints
    func createMeal(_ request: CreateMealRequest, token: String) async throws -> MealResponse {
        return try await self.request(
            endpoint: "/meals",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    // MARK: - Helper Methods for DELETE/PATCH with no response body
    private func deleteRequest(endpoint: String, token: String) async throws {
        let fullURL = "\(baseURL)\(endpoint)"
        print("🌐 API Request: DELETE \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 204 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        print("✅ DELETE request successful")
    }
    
    private func patchRequest(endpoint: String, body: Encodable, token: String) async throws {
        let fullURL = "\(baseURL)\(endpoint)"
        print("🌐 API Request: PATCH \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 204 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        print("✅ PATCH request successful")
    }
}

// Empty response for DELETE/PATCH operations that return no body
struct EmptyDeleteResponse: Decodable {
    init() {}
}

// MARK: - Error Types
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Response Models
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T?
    let errors: [String]?
    let timestamp: String?
}

struct APIErrorResponse: Decodable {
    let success: Bool?
    let message: String?
    let errors: [String]?
}

// Empty response for error parsing
private struct EmptyResponse: Decodable {}

// MARK: - Auth Request Models
struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let fullName: String
    let role: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

// MARK: - Wearable Stats
/// Body for `POST /users/me/wearable-stats`. Metrics are optional; send only what HealthKit provided.
struct WearableStatsRequest: Encodable {
    /// Local calendar day, `yyyy-MM-dd`.
    let date: String
    let avgHeartRate: Int?
    let steps: Int?
    let activeCalories: Int?
    let source: String

    init(date: String, avgHeartRate: Int?, steps: Int?, activeCalories: Int?, source: String = "HEALTHKIT") {
        self.date = date
        self.avgHeartRate = avgHeartRate
        self.steps = steps
        self.activeCalories = activeCalories
        self.source = source
    }
}

struct WearableStatsResponse: Decodable {
    let date: String?
    let avgHeartRate: Int?
    let steps: Int?
    let activeCalories: Int?
    let updatedAt: String?
}

// MARK: - Auth Response Models
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int64
}

