//
//  HealthRecordView.swift
//  tawazon
//

import SwiftUI
import UniformTypeIdentifiers

struct HealthRecordView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var model = HealthRecordViewModel()
    @State private var showPdfImporter = false
    @State private var showImageImporter = false

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                stepIndicator
                ScrollView {
                    Group {
                        switch model.step {
                        case 0: stepBasic
                        case 1: stepMeasurements
                        case 2: stepGoals
                        default: stepUploads
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)

                HStack {
                    if model.canGoBack {
                        AppButton(title: languageManager.localize("common.back"), style: .outline) {
                            model.back()
                        }
                    }
                    if model.canGoNext {
                        AppButton(title: languageManager.localize("common.next"), style: .primary) {
                            model.next()
                        }
                    } else {
                        AppButton(
                            title: languageManager.localize("health.submit"),
                            style: .primary,
                            isLoading: model.isSubmitting
                        ) {
                            guard let t = KeychainService.shared.getAccessToken() else { return }
                            Task { await model.submit(token: t) }
                        }
                    }
                }
                if let err = model.errorMessage {
                    Text(err).font(.caption).foregroundColor(.red)
                }
            }
            .padding()
        }
        .navigationTitle(languageManager.localize("health.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert(languageManager.localize("health.successTitle"), isPresented: Binding(
            get: { model.submitSuccess },
            set: { if !$0 { model.submitSuccess = false } }
        )) {
            Button(languageManager.localize("common.ok")) {
                model.submitSuccess = false
                dismiss()
            }
        } message: {
            Text(languageManager.localize("health.successBody"))
        }
        .fileImporter(isPresented: $showPdfImporter, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result, url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                model.inbodyPDFData = try? Data(contentsOf: url)
                model.inbodyFilename = url.lastPathComponent
            }
        }
        .fileImporter(isPresented: $showImageImporter, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result, url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                if let d = try? Data(contentsOf: url) {
                    model.photoDataList.append(d)
                }
            }
        }
    }

    private var stepIndicator: some View {
        Text("\(languageManager.localize("health.step")) \(model.step + 1)/\(model.totalSteps)")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private var stepBasic: some View {
        VStack(spacing: 12) {
            metricField(languageManager.localize("health.height"), $model.height, languageManager.localize("units.cm"))
            metricField(languageManager.localize("progress.weight"), $model.weight, languageManager.localize("units.kg"))
            metricField(languageManager.localize("health.age"), $model.age, "")
            genderField
        }
    }

    private var genderField: some View {
        let options: [(value: String, label: String)] = [
            ("MALE", languageManager.localize("health.gender.male")),
            ("FEMALE", languageManager.localize("health.gender.female")),
            ("OTHER", languageManager.localize("health.gender.other")),
            ("PREFER_NOT_TO_SAY", languageManager.localize("health.gender.preferNot")),
        ]
        let selectedLabel = options.first { $0.value == model.gender }?.label
        return VStack(alignment: .leading, spacing: 4) {
            Text(languageManager.localize("health.gender")).font(.caption).foregroundColor(.secondary)
            Menu {
                ForEach(options, id: \.value) { option in
                    Button(option.label) { model.gender = option.value }
                }
            } label: {
                HStack {
                    Text(selectedLabel ?? languageManager.localize("health.gender.hint"))
                        .foregroundColor(selectedLabel == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down").foregroundColor(.secondary)
                }
                .padding()
                .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                .cornerRadius(10)
            }
        }
    }

    private var stepMeasurements: some View {
        VStack(spacing: 12) {
            metricField(languageManager.localize("health.measure.waist"), $model.waistCm, languageManager.localize("units.cm"))
            metricField(languageManager.localize("health.measure.chest"), $model.chestCm, languageManager.localize("units.cm"))
            metricField(languageManager.localize("health.measure.leftArm"), $model.leftArmCm, languageManager.localize("units.cm"))
            metricField(languageManager.localize("health.measure.rightArm"), $model.rightArmCm, languageManager.localize("units.cm"))
            metricField(languageManager.localize("health.measure.leftThigh"), $model.leftThighCm, languageManager.localize("units.cm"))
            metricField(languageManager.localize("health.measure.rightThigh"), $model.rightThighCm, languageManager.localize("units.cm"))
            metricField(languageManager.localize("health.measure.hips"), $model.hipsCm, languageManager.localize("units.cm"))
            metricField(languageManager.localize("health.measure.neck"), $model.neckCm, languageManager.localize("units.cm"))
        }
    }

    private var stepGoals: some View {
        VStack(spacing: 12) {
            multiline(languageManager.localize("health.fitnessGoals"), $model.fitnessGoals)
            multiline(languageManager.localize("health.medical"), $model.medicalConditions)
            multiline(languageManager.localize("health.allergies"), $model.allergies)
            multiline(languageManager.localize("health.notesToCoach"), $model.notesToCoach)
        }
    }

    private var stepUploads: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { showPdfImporter = true }) {
                Label(
                    model.inbodyPDFData == nil ? languageManager.localize("health.addPdf") : languageManager.localize("health.pdfSelected"),
                    systemImage: "doc.fill"
                )
            }
            Button(action: { showImageImporter = true }) {
                Label(languageManager.localize("health.addPhoto"), systemImage: "photo")
            }
            Text(String(format: languageManager.localize("health.photoCount"), model.photoDataList.count))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func metricField(_ title: String, _ text: Binding<String>, _ suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            HStack {
                TextField(title, text: text)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                    .cornerRadius(10)
                if !suffix.isEmpty {
                    Text(suffix).foregroundColor(.secondary)
                }
            }
        }
    }

    private func multiline(_ title: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextField(title, text: text, axis: .vertical)
                .lineLimit(3...8)
                .padding()
                .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                .cornerRadius(10)
        }
    }
}
