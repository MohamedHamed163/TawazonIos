//
//  CoachDetailViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class CoachDetailViewModel {
    let coachId: String
    private let api = APIService.shared

    var coach: CoachProfileDTO?
    var plans: [CoachPlan] = []
    var isLoading = false
    var plansLoading = false
    var errorMessage: String?
    var checkoutLoadingPlanId: String?
    var isSubscribedToThisCoach = false

    init(coachId: String) {
        self.coachId = coachId
    }

    func load(token: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            coach = try await api.getCoach(id: coachId, token: token)
            await loadPlans(token: token)
            if let t = token {
                await refreshSubscriptionStateInternal(token: t)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Call when returning from Safari (e.g. after Stripe checkout) to pick up new subscriptions.
    func refreshSubscriptionState(token: String) async {
        await refreshSubscriptionStateInternal(token: token)
    }

    func loadPlans(token: String?) async {
        plansLoading = true
        defer { plansLoading = false }
        do {
            let page = try await api.getCoachPlans(coachId: coachId, page: 0, size: 50, token: token)
            plans = page.content.filter { $0.active != false }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshSubscriptionStateInternal(token: String) async {
        do {
            let subs = try await api.getSubscriptions(page: 0, size: 50, token: token)
            isSubscribedToThisCoach = subs.content.contains {
                $0.status.uppercased() == "ACTIVE" && $0.coachProfile?.id == coachId
            }
        } catch {
            isSubscribedToThisCoach = false
        }
    }

    func checkoutURL(for planId: String, token: String) async throws -> URL {
        checkoutLoadingPlanId = planId
        defer { checkoutLoadingPlanId = nil }
        let res = try await api.subscriptionCheckout(SubscriptionCheckoutRequest(planId: planId), token: token)
        guard let u = URL(string: res.checkoutUrl) else { throw APIError.invalidURL }
        return u
    }
}
