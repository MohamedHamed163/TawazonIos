//
//  APIService.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation

extension Notification.Name {
    static let tawazonSessionExpired = Notification.Name("tawazonSessionExpired")
}

class APIService {
    static let shared = APIService()

    // Override at launch via:
    //   xcrun simctl launch <udid> dev.tawazon -TAWAZON_API_BASE_URL "http://localhost:8090/api/v1"
    // or via the TAWAZON_API_BASE_URL environment variable when running from Xcode.
    private let baseURL: String = {
        if let arg = UserDefaults.standard.string(forKey: "TAWAZON_API_BASE_URL"), !arg.isEmpty {
            return arg
        }
        if let env = ProcessInfo.processInfo.environment["TAWAZON_API_BASE_URL"], !env.isEmpty {
            return env
        }
        return "https://api.tawazon-fitness.com/api/v1"
    }()

    /// STOMP/WebSocket endpoint derived from the REST base URL
    /// (e.g. https://host/api/v1 -> wss://host/ws/websocket).
    var webSocketURL: URL? {
        guard var comps = URLComponents(string: baseURL) else { return nil }
        comps.scheme = (comps.scheme == "http") ? "ws" : "wss"
        comps.path = "/ws/websocket"
        comps.query = nil
        return comps.url
    }

    private init() {}

    // MARK: - Session refresh (single-flight)
    private actor RefreshCoordinator {
        private var refreshTask: Task<Bool, Never>?

        func refresh(using api: APIService) async -> Bool {
            if let task = refreshTask {
                return await task.value
            }
            let task = Task {
                await api.performTokenRefresh()
            }
            refreshTask = task
            let ok = await task.value
            refreshTask = nil
            return ok
        }
    }

    private let refreshCoordinator = RefreshCoordinator()

    private func performTokenRefresh() async -> Bool {
        guard let refresh = KeychainService.shared.getRefreshToken() else { return false }
        do {
            let auth: AuthResponse = try await request(
                endpoint: "/auth/refresh",
                method: "POST",
                body: RefreshTokenRequest(refreshToken: refresh),
                token: nil,
                language: nil,
                didRetryAfterRefresh: false
            )
            KeychainService.shared.saveAccessToken(auth.accessToken)
            KeychainService.shared.saveRefreshToken(auth.refreshToken)
            return true
        } catch {
            return false
        }
    }

    private func handleUnauthorizedAfterRefreshFailed() {
        KeychainService.shared.clearAllTokens()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .tawazonSessionExpired, object: nil)
        }
    }

    /// Human-readable `DecodingError` for Xcode console when debugging API shapes.
    private func decodingDebugDescription(_ error: Error) -> String {
        guard let e = error as? DecodingError else { return String(describing: error) }
        switch e {
        case .keyNotFound(let key, let ctx):
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return "keyNotFound '\(key.stringValue)' codingPath=[\(path)]"
        case .typeMismatch(let type, let ctx):
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return "typeMismatch \(type) codingPath=[\(path)]"
        case .valueNotFound(let type, let ctx):
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return "valueNotFound \(type) codingPath=[\(path)]"
        case .dataCorrupted(let ctx):
            return "dataCorrupted: \(ctx.debugDescription)"
        @unknown default:
            return String(describing: e)
        }
    }
    
    // MARK: - HTTP transport (shared by `request` and specialized decoders)
    private func fetchResponseBody(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        token: String? = nil,
        language: String? = nil,
        didRetryAfterRefresh: Bool = false
    ) async throws -> (Data, HTTPURLResponse) {
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

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString.prefix(500))")
        }

        if httpResponse.statusCode == 401 {
            if let token = token, !token.isEmpty {
                if !didRetryAfterRefresh {
                    let refreshed = await refreshCoordinator.refresh(using: self)
                    if refreshed, let newToken = KeychainService.shared.getAccessToken() {
                        return try await fetchResponseBody(
                            endpoint: endpoint,
                            method: method,
                            body: body,
                            token: newToken,
                            language: language,
                            didRetryAfterRefresh: true
                        )
                    }
                }
                handleUnauthorizedAfterRefreshFailed()
                throw APIError.unauthorized
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                if let errors = errorResponse.errors, !errors.isEmpty {
                    let errorMessage = errors.joined(separator: "\n")
                    print("❌ Server errors: \(errorMessage)")
                    throw APIError.serverError(errorMessage)
                }
                let errorMessage = errorResponse.message ?? "Server error"
                print("❌ Server error: \(errorMessage)")
                throw APIError.serverError(errorMessage)
            }

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

            throw APIError.httpError(httpResponse.statusCode)
        }

        return (data, httpResponse)
    }

    // MARK: - Generic Request Method
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        token: String? = nil,
        language: String? = nil,
        didRetryAfterRefresh: Bool = false
    ) async throws -> T {
        do {
            let (data, httpResponse) = try await fetchResponseBody(
                endpoint: endpoint,
                method: method,
                body: body,
                token: token,
                language: language,
                didRetryAfterRefresh: didRetryAfterRefresh
            )

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
                if apiResponse.success {
                    if let data = apiResponse.data {
                        print("✅ Request successful")
                        return data
                    }
                    if T.self == APINoData.self {
                        print("✅ Request successful (no data body)")
                        return APINoData.ok as! T
                    }
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
    
    func loginWithApple(token: String, fullName: String?, email: String?) async throws -> AuthResponse {
        let body = AppleLoginRequest(identityToken: token, fullName: fullName, email: email)
        return try await self.request(
            endpoint: "/auth/apple",
            method: "POST",
            body: body
        )
    }
    
    func loginWithGoogle(token: String) async throws -> AuthResponse {
        let body = GoogleLoginRequest(idToken: token)
        return try await self.request(
            endpoint: "/auth/google",
            method: "POST",
            body: body
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
    /// Idempotent on the backend (keyed by user + date), so sending repeatedly is safe.
    func syncWearableStats(_ request: WearableStatsRequest, token: String) async throws {
        let _: APINoData = try await self.request(
            endpoint: "/users/me/wearable-stats",
            method: "POST",
            body: request,
            token: token
        )
    }

    // MARK: - Coaches Endpoints
    func getCoaches(page: Int = 0, size: Int = 20, token: String? = nil) async throws -> PageResponse<CoachProfileDTO> {
        return try await self.request(
            endpoint: "/coaches?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }
    
    func getCoach(id: String, token: String? = nil) async throws -> CoachProfileDTO {
        return try await self.request(
            endpoint: "/coaches/\(id)",
            method: "GET",
            token: token
        )
    }
    
    func getFeaturedCoaches(token: String) async throws -> [CoachProfileDTO] {
        return try await self.request(
            endpoint: "/coaches/featured",
            method: "GET",
            token: token
        )
    }
    
    func getCoachPlans(coachId: String, page: Int = 0, size: Int = 20, token: String?) async throws -> PageResponse<CoachPlan> {
        return try await self.request(
            endpoint: "/coaches/\(coachId)/plans?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }
    
    func createCoachProfile(_ request: CreateCoachProfileRequest, token: String) async throws -> CoachProfileDTO {
        return try await self.request(
            endpoint: "/coaches",
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func updateCoachProfile(id: String, _ request: UpdateCoachProfileRequest, token: String) async throws -> CoachProfileDTO {
        return try await self.request(
            endpoint: "/coaches/\(id)",
            method: "PUT",
            body: request,
            token: token
        )
    }
    
    // MARK: - Programs Endpoints
    func getPrograms(page: Int = 0, size: Int = 20, token: String? = nil) async throws -> PageResponse<ProgramResponse> {
        return try await self.request(
            endpoint: "/programs?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }

    func getProgram(id: String, token: String? = nil) async throws -> ProgramResponse {
        return try await self.request(
            endpoint: "/programs/\(id)",
            method: "GET",
            token: token
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
    func getVideos(page: Int = 0, size: Int = 20, token: String? = nil) async throws -> PageResponse<VideoMetadataResponse> {
        return try await self.request(
            endpoint: "/content/videos?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }

    func getVideo(id: String, token: String? = nil) async throws -> VideoMetadataResponse {
        return try await self.request(
            endpoint: "/content/videos/\(id)",
            method: "GET",
            token: token
        )
    }

    // Likes (reels): toggle a heart on a video. Both return the updated count + liked-state.
    func likeVideo(id: String, token: String? = nil) async throws -> VideoLikeResponse {
        return try await self.request(
            endpoint: "/content/videos/\(id)/like",
            method: "POST",
            token: token
        )
    }

    func unlikeVideo(id: String, token: String? = nil) async throws -> VideoLikeResponse {
        return try await self.request(
            endpoint: "/content/videos/\(id)/like",
            method: "DELETE",
            token: token
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
    func getSubscriptions(page: Int = 0, size: Int = 20, token: String) async throws -> PageResponse<SubscriptionDetailDTO> {
        return try await self.request(
            endpoint: "/subscriptions?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }
    
    func getSubscription(id: String, token: String) async throws -> SubscriptionDetailDTO {
        return try await self.request(
            endpoint: "/subscriptions/\(id)",
            method: "GET",
            token: token
        )
    }
    
    func subscriptionCheckout(_ body: SubscriptionCheckoutRequest, token: String) async throws -> CheckoutResponse {
        return try await self.request(
            endpoint: "/subscriptions/checkout",
            method: "POST",
            body: body,
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
    
    func cancelSubscription(id: String, token: String) async throws -> SubscriptionDetailDTO {
        return try await self.request(
            endpoint: "/subscriptions/\(id)/cancel",
            method: "PATCH",
            token: token
        )
    }
    
    func toggleSubscriptionAutoRenew(id: String, _ body: ToggleAutoRenewRequest, token: String) async throws -> SubscriptionDetailDTO {
        return try await self.request(
            endpoint: "/subscriptions/\(id)/auto-renew",
            method: "PATCH",
            body: body,
            token: token
        )
    }
    
    // MARK: - Dashboard & Today Program
    func getDashboard(token: String) async throws -> DashboardResponse {
        return try await self.request(endpoint: "/dashboard", method: "GET", token: token)
    }
    
    /// `nil` when the API reports success but `data` is empty (e.g. no program assigned yet).
    func getTodaySchedule(token: String) async throws -> TodayScheduleResponse? {
        do {
            let (data, http) = try await fetchResponseBody(endpoint: "/programs/today", method: "GET", token: token)
            let utf8 = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            let maxLog = 4_000
            let suffix = utf8.count > maxLog ? "\n… (\(utf8.count - maxLog) more chars truncated)" : ""
            print("🧩 [programs/today] HTTP \(http.statusCode) bodyBytes=\(data.count)")
            print("🧩 [programs/today] raw JSON (up to \(maxLog) chars):\n\(String(utf8.prefix(maxLog)))\(suffix)")

            if data.isEmpty {
                print("ℹ️ [programs/today] empty body → nil schedule")
                return nil
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                let apiResponse = try decoder.decode(APIResponse<TodayScheduleResponse>.self, from: data)
                print("🧩 [programs/today] envelope decoded success=\(apiResponse.success) dataIsNil=\(apiResponse.data == nil) message=\(apiResponse.message ?? "nil")")
                if apiResponse.success {
                    if let schedule = apiResponse.data {
                        print("✅ [programs/today] returning schedule programId=\(schedule.programId) workouts=\(schedule.todayWorkouts.count)")
                        return schedule
                    }
                    print("ℹ️ [programs/today] success + data nil → no program assigned (UI empty state)")
                    return nil
                }
                let errorMessage = apiResponse.message ?? "Request failed"
                print("❌ [programs/today] envelope success=false → \(errorMessage)")
                throw APIError.serverError(errorMessage)
            } catch let err as DecodingError {
                print("🧩 [programs/today] ApiResponse<TodayScheduleResponse> DECODE FAILED → \(decodingDebugDescription(err))")
                let decoder2 = JSONDecoder()
                decoder2.dateDecodingStrategy = .iso8601
                do {
                    let schedule = try decoder2.decode(TodayScheduleResponse.self, from: data)
                    print("✅ [programs/today] fallback direct TodayScheduleResponse decode succeeded")
                    return schedule
                } catch {
                    print("🧩 [programs/today] fallback direct decode FAILED → \(decodingDebugDescription(error))")
                    throw error
                }
            } catch let apiErr as APIError {
                throw apiErr
            } catch {
                print("🧩 [programs/today] unexpected after envelope path: \(error)")
                throw error
            }
        } catch let error as APIError {
            print("❌ [programs/today] APIError: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ [programs/today] thrown: \(decodingDebugDescription(error)) | localized=\(error.localizedDescription)")
            throw error
        }
    }
    
    func completeTodayWorkout(token: String) async throws -> TodayScheduleResponse {
        return try await self.request(
            endpoint: "/programs/today/complete",
            method: "PATCH",
            token: token
        )
    }
    
    func skipTodayWorkout(token: String) async throws -> TodayScheduleResponse {
        return try await self.request(
            endpoint: "/programs/today/skip",
            method: "PATCH",
            token: token
        )
    }
    
    func getProgressSummary(token: String) async throws -> ProgressSummary {
        return try await self.request(endpoint: "/users/me/progress/summary", method: "GET", token: token)
    }
    
    // MARK: - Health records
    func submitHealthRecord(_ body: CreateHealthRecordRequest, token: String) async throws -> HealthRecord {
        return try await self.request(
            endpoint: "/health/records",
            method: "POST",
            body: body,
            token: token
        )
    }
    
    func getHealthRecords(page: Int = 0, size: Int = 20, token: String) async throws -> PageResponse<HealthRecord> {
        return try await self.request(
            endpoint: "/health/records?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }
    
    func getLatestHealthRecord(token: String) async throws -> HealthRecord {
        return try await self.request(
            endpoint: "/health/records/latest",
            method: "GET",
            token: token
        )
    }
    
    // MARK: - Notifications
    func getNotifications(page: Int = 0, size: Int = 20, token: String) async throws -> PageResponse<AppNotificationDTO> {
        return try await self.request(
            endpoint: "/notifications?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }
    
    func markNotificationRead(id: String, token: String) async throws -> AppNotificationDTO {
        return try await self.request(
            endpoint: "/notifications/\(id)/read",
            method: "PATCH",
            token: token
        )
    }
    
    func markAllNotificationsRead(token: String) async throws {
        let _: APINoData = try await self.request(
            endpoint: "/notifications/read-all",
            method: "PATCH",
            token: token
        )
    }
    
    func getUnreadNotificationCount(token: String) async throws -> Int {
        return try await self.request(
            endpoint: "/notifications/unread-count",
            method: "GET",
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

    // MARK: - Messaging / Chat
    func getMyConversations(page: Int = 0, size: Int = 20, token: String) async throws -> PageResponse<UserConversationDTO> {
        return try await self.request(
            endpoint: "/conversations?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }

    func startConversation(coachProfileId: String, token: String) async throws -> UserConversationDTO {
        return try await self.request(
            endpoint: "/conversations",
            method: "POST",
            body: StartConversationRequestDTO(coachProfileId: coachProfileId),
            token: token
        )
    }

    func getMessages(conversationId: String, page: Int = 0, size: Int = 30, token: String) async throws -> PageResponse<MessageDTO> {
        return try await self.request(
            endpoint: "/conversations/\(conversationId)/messages?page=\(page)&size=\(size)",
            method: "GET",
            token: token
        )
    }

    func sendMessage(conversationId: String, _ body: SendMessageRequestDTO, token: String) async throws -> MessageDTO {
        return try await self.request(
            endpoint: "/conversations/\(conversationId)/messages",
            method: "POST",
            body: body,
            token: token
        )
    }

    func markConversationRead(conversationId: String, token: String) async throws {
        let _: APINoData = try await self.request(
            endpoint: "/conversations/\(conversationId)/read",
            method: "PATCH",
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

/// Use with `APIService.request` when the API returns `success: true` with no `data` payload.
enum APINoData: Decodable {
    case ok
    init(from decoder: Decoder) throws {
        self = .ok
    }
}

// MARK: - Error Types
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case decodingError
    case unauthorized
    
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
        case .unauthorized:
            return "Session expired. Please sign in again."
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

struct AppleLoginRequest: Encodable {
    let identityToken: String
    let fullName: String?
    let email: String?
}

struct GoogleLoginRequest: Encodable {
    let idToken: String
}

// MARK: - Auth Response Models
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int64
}

