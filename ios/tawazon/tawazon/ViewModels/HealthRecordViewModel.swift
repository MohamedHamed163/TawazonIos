//
//  HealthRecordViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class HealthRecordViewModel {
    private let api = APIService.shared
    private let uploads = FileUploadManager.shared

    var step = 0
    var height = ""
    var weight = ""
    var age = ""
    var gender = ""
    var waistCm = ""
    var chestCm = ""
    var leftArmCm = ""
    var rightArmCm = ""
    var leftThighCm = ""
    var rightThighCm = ""
    var hipsCm = ""
    var neckCm = ""
    var fitnessGoals = ""
    var medicalConditions = ""
    var allergies = ""
    var notesToCoach = ""
    var inbodyPDFData: Data?
    var inbodyFilename = "inbody-report.pdf"
    var photoDataList: [Data] = []
    var isSubmitting = false
    var errorMessage: String?
    var submitSuccess = false

    var totalSteps: Int { 4 }
    var canGoNext: Bool { step < totalSteps - 1 }
    var canGoBack: Bool { step > 0 }

    func next() {
        if canGoNext { step += 1 }
    }

    func back() {
        if canGoBack { step -= 1 }
    }

    func submit(token: String) async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        var reportKey: String?
        if let data = inbodyPDFData {
            do {
                reportKey = try await uploads.uploadFile(
                    data: data,
                    filename: inbodyFilename,
                    contentType: "application/pdf",
                    token: token
                )
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        var photoKeys: [String] = []
        for (index, data) in photoDataList.enumerated() {
            do {
                let key = try await uploads.uploadFile(
                    data: data,
                    filename: "progress-\(index).jpg",
                    contentType: "image/jpeg",
                    token: token
                )
                photoKeys.append(key)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        var req = CreateHealthRecordRequest()
        req.height = Double(height)
        req.weight = Double(weight)
        req.age = Int(age)
        req.gender = gender.isEmpty ? nil : gender
        req.fitnessGoals = fitnessGoals.isEmpty ? nil : fitnessGoals
        req.medicalConditions = medicalConditions.isEmpty ? nil : medicalConditions
        req.allergies = allergies.isEmpty ? nil : allergies
        req.notesToCoach = notesToCoach.isEmpty ? nil : notesToCoach
        req.inbodyReportUrl = reportKey
        req.waistCm = Double(waistCm)
        req.chestCm = Double(chestCm)
        req.leftArmCm = Double(leftArmCm)
        req.rightArmCm = Double(rightArmCm)
        req.leftThighCm = Double(leftThighCm)
        req.rightThighCm = Double(rightThighCm)
        req.hipsCm = Double(hipsCm)
        req.neckCm = Double(neckCm)
        req.progressPhotoUrls = photoKeys.isEmpty ? nil : photoKeys

        do {
            _ = try await api.submitHealthRecord(req, token: token)
            submitSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
