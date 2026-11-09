//
//  ProgressDashboardView.swift
//  tawazon
//

import Charts
import SwiftUI

enum ChartRange: CaseIterable {
    case month, year, all

    var labelKey: String {
        switch self {
        case .month: return "progress.month"
        case .year: return "progress.year"
        case .all: return "progress.all"
        }
    }

    /// Number of days back from today this range covers; nil = all time.
    var days: Int? {
        switch self {
        case .month: return 30
        case .year: return 365
        case .all: return nil
        }
    }
}

struct ProgressDashboardView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = ProgressDashboardViewModel()
    @State private var range: ChartRange = .all
    @State private var selectedDate: Date?

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }
    private var accent: Color { themeManager.dynamicColorTheme.currentPrimary }

    private var filteredSeries: [WeightPoint] {
        let all = model.weightSeries
        guard let days = range.days,
              let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return all }
        let filtered = all.filter { $0.date >= cutoff }
        return filtered.count >= 2 ? filtered : all
    }

    private var selectedPoint: WeightPoint? {
        guard let selectedDate else { return nil }
        return filteredSeries.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            if model.isLoading && model.summary == nil {
                ScrollView {
                    SkeletonList(count: 3, lines: 4)
                        .padding()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summarySection
                        weightChartSection
                        measurementsSection
                        photosSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(languageManager.localize("progress.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    @ViewBuilder
    private var summarySection: some View {
        if let s = model.summary {
            HStack(spacing: 12) {
                StatCard(
                    icon: "scalemass",
                    value: s.currentWeight.map { String(format: "%.1f", $0) } ?? "--",
                    label: languageManager.localize("progress.weight"),
                    color: accent
                )
                StatCard(
                    icon: "arrow.down.right",
                    value: s.weightChange.map { String(format: "%+.1f", $0) } ?? "--",
                    label: languageManager.localize("progress.change"),
                    color: .orange
                )
                StatCard(
                    icon: "flame.fill",
                    value: "\(s.streakDays ?? 0)",
                    label: languageManager.localize("home.streakDays"),
                    color: .red
                )
            }
        }
    }

    @ViewBuilder
    private var weightChartSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(languageManager.localize("progress.weightHistory"))
                        .textStyle(Typography.Style.headlineBold, color: textPrimary)
                    Spacer()
                    if let sp = selectedPoint {
                        Text(String(format: "%.1f kg", sp.weight))
                            .textStyle(Typography.Style.subheadlineBold, color: accent)
                    }
                }
                if model.weightSeries.count < 2 {
                    Text(languageManager.localize("progress.notEnoughData"))
                        .textStyle(Typography.Style.caption, color: textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    rangePicker
                    weightChart
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rangePicker: some View {
        Picker("", selection: $range) {
            ForEach(ChartRange.allCases, id: \.self) { r in
                Text(languageManager.localize(r.labelKey)).tag(r)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: range) { _, _ in
            Haptics.selection()
            selectedDate = nil
        }
    }

    @ViewBuilder
    private var weightChart: some View {
        Chart(filteredSeries) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(accent)
            .interpolationMethod(.catmullRom)
            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(accent)
            .symbolSize(selectedPoint?.id == point.id ? 160 : 40)

            if let sp = selectedPoint {
                RuleMark(x: .value("Date", sp.date))
                    .foregroundStyle(accent.opacity(0.35))
                    .annotation(position: .top, alignment: .center) {
                        Text(String(format: "%.1f", sp.weight))
                            .textStyle(Typography.Style.caption2, color: textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accent.opacity(0.18), in: Capsule())
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXSelection(value: $selectedDate)
        .frame(height: 220)
    }

    @ViewBuilder
    private var measurementsSection: some View {
        if let r = model.latestRecord {
            let rows = measurementRows(r)
            if !rows.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.localize("progress.measurements"))
                            .textStyle(Typography.Style.headlineBold, color: textPrimary)
                        ForEach(rows, id: \.label) { row in
                            HStack {
                                Text(row.label)
                                    .textStyle(Typography.Style.subheadline, color: textSecondary)
                                Spacer()
                                Text(String(format: "%.1f cm", row.value))
                                    .textStyle(Typography.Style.subheadlineBold, color: textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func measurementRows(_ r: HealthRecord) -> [(label: String, value: Double)] {
        var rows: [(String, Double)] = []
        func add(_ key: String, _ v: Double?) { if let v { rows.append((languageManager.localize(key), v)) } }
        add("health.measure.waist", r.waistCm)
        add("health.measure.chest", r.chestCm)
        add("health.measure.hips", r.hipsCm)
        add("health.measure.neck", r.neckCm)
        add("health.measure.leftArm", r.leftArmCm)
        add("health.measure.rightArm", r.rightArmCm)
        add("health.measure.leftThigh", r.leftThighCm)
        add("health.measure.rightThigh", r.rightThighCm)
        return rows
    }

    @ViewBuilder
    private var photosSection: some View {
        let photos = model.progressPhotos
        if !photos.isEmpty {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("progress.photos"))
                        .textStyle(Typography.Style.headlineBold, color: textPrimary)
                    if photos.count >= 2 {
                        HStack(spacing: 12) {
                            photoColumn(label: languageManager.localize("progress.first"), url: photos.first)
                            photoColumn(label: languageManager.localize("progress.latest"), url: photos.last)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(photos, id: \.self) { url in
                                    photoThumb(url)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func photoColumn(label: String, url: String?) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .textStyle(Typography.Style.caption, color: textSecondary)
            if let url { photoThumb(url) } else {
                Rectangle().fill(textSecondary.opacity(0.15))
                    .frame(height: 200).cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func photoThumb(_ urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let img):
                img.resizable().aspectRatio(contentMode: .fill)
            default:
                Rectangle().fill(textSecondary.opacity(0.15))
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(12)
    }
}
