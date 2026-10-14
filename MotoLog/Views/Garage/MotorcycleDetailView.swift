//
//  MotorcycleDetailView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

struct MotorcycleDetailView: View {
    @Bindable var motorcycle: Motorcycle
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingParts = false
    @State private var isShowingUpdateMileage = false

    private var mostUrgentItem: MaintenanceItem? {
        motorcycle.maintenanceItems.min {
            $0.milesRemaining(currentMileage: motorcycle.currentMileage)
                < $1.milesRemaining(currentMileage: motorcycle.currentMileage)
        }
    }

    /// Fixed height for the placeholder hero shown before a photo exists —
    /// once there's a real photo, `MotorcyclePhotoView` sizes itself from
    /// the photo's own aspect ratio instead, so there's no fixed number here
    /// for that case.
    private let placeholderHeroHeight: CGFloat = 380
    /// Vertical gap between the bike's title and the quick-stats row below
    /// it — kept identical whether the title is overlaid on a photo or shown
    /// as a plain heading with no photo, so the two states read as the same
    /// layout rather than drifting (previously the title's own bottom
    /// padding and quickStats' pull-up-to-overlap offset were two unrelated
    /// numbers that happened to nearly cancel out).
    private let titleToStatsGap: CGFloat = 20
    /// How far quickStats overlaps up into the hero's bottom fade, so the
    /// photo visually bleeds into the stats instead of the two just stacking.
    private let heroBleedOverlap: CGFloat = 14

    var body: some View {
        // A plain ScrollView, not a List: List imposes its own automatic
        // top content inset tied to the safe area, which silently overrides
        // a row's `.ignoresSafeArea()` — there's no public lever to turn
        // that off, so the hero photo could never actually reach the status
        // bar while living inside a List. ScrollView doesn't fight this.
        ScrollView {
            VStack(spacing: 0) {
                heroHeader

                VStack(alignment: .leading, spacing: titleToStatsGap) {
                    // With no photo yet, there's nothing for the hero's
                    // overlay title to sit on top of, so the name reads as a
                    // normal heading here instead.
                    if motorcycle.photoData == nil {
                        titleRow
                    }

                    quickStats

                    sectionCard("Overview") {
                        VStack(spacing: 0) {
                            TextField("Nickname", text: Binding(
                                get: { motorcycle.nickname ?? "" },
                                set: { motorcycle.nickname = $0.isEmpty ? nil : $0 }
                            ), prompt: Text(motorcycle.subtitle))
                            .padding(12)

                            Divider().padding(.leading, 12)

                            Button {
                                isShowingUpdateMileage = true
                            } label: {
                                LabeledContent("Current Mileage", value: "\(motorcycle.currentMileage.formatted()) mi")
                            }
                            .tint(.primary)
                            .padding(12)
                        }
                    }

                    sectionCard("Maintenance") {
                        MaintenanceSectionView(motorcycle: motorcycle)
                            .padding(12)
                    }

                    sectionCard {
                        Button {
                            appState.selectedMotorcycleID = motorcycle.id
                            isShowingParts = true
                        } label: {
                            Label("Shop Parts for This Bike", systemImage: "shippingbox")
                        }
                        .padding(12)
                    }

                    sectionCard {
                        Button("Delete Motorcycle", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                        .padding(12)
                    }
                }
                // One shared horizontal inset for every section below the
                // hero, so quick-stats and the cards underneath always line
                // up edge-to-edge instead of drifting from mismatched
                // per-section padding.
                .padding(.horizontal)
                .padding(.top, motorcycle.photoData == nil ? titleToStatsGap : -heroBleedOverlap)
                .padding(.bottom, 24)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $isShowingUpdateMileage) {
            UpdateMileageView(motorcycle: motorcycle)
        }
        .confirmationDialog(
            "Delete \(motorcycle.displayName)?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if appState.selectedMotorcycleID == motorcycle.id {
                    appState.selectedMotorcycleID = nil
                }
                modelContext.delete(motorcycle)
                dismiss()
            }
        } message: {
            Text("This removes the bike and all of its maintenance history. This can't be undone.")
        }
        .sheet(isPresented: $isShowingParts) {
            NavigationStack {
                PartsBrowseView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { isShowingParts = false }
                        }
                    }
            }
        }
    }

    /// Full-bleed photo (or placeholder) at the top of the screen — the bike
    /// is the point of this app, so its photo gets to lead rather than share
    /// space with a small square thumbnail.
    ///
    /// Structured like `TripDetailView`'s map header on purpose: the photo
    /// layer is the only thing that ignores the safe area, while the back/
    /// edit buttons sit in a sibling layer that doesn't — so they rest at
    /// the safe area's natural position (just below the Dynamic Island)
    /// instead of needing a guessed top padding to clear it.
    private var heroHeader: some View {
        let hasPhoto = motorcycle.photoData != nil
        return ZStack(alignment: .top) {
            heroPhoto(hasPhoto: hasPhoto)
                .ignoresSafeArea(edges: .top)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                }
                Spacer()
                MotorcyclePhotoEditButton(motorcycle: motorcycle)
            }
            .padding(.horizontal)
        }
    }

    private func heroPhoto(hasPhoto: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            MotorcyclePhotoView(motorcycle: motorcycle, size: placeholderHeroHeight, isHero: true)

            // With no photo, the hero is just the placeholder/"Add Photo"
            // prompt — overlaying title text on it would fight with that
            // prompt for the same small area, so the name moves to a plain
            // heading below instead (see `titleRow`).
            if hasPhoto {
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(motorcycle.displayName)
                        .font(.title.weight(.bold))
                    if motorcycle.nickname?.isEmpty == false {
                        Text(motorcycle.subtitle)
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.top)
                // Bottom padding is deliberately larger than the top/sides:
                // it has to clear both the gap quickStats overlaps up by
                // (heroBleedOverlap) and the gap we actually want between
                // the title and quickStats (titleToStatsGap), so the two add
                // up rather than fighting each other into a near-zero gap.
                .padding(.bottom, titleToStatsGap + heroBleedOverlap)
            }
        }
        .frame(height: hasPhoto ? nil : placeholderHeroHeight)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay(alignment: .bottom) {
            if hasPhoto {
                // Fades the photo's bottom edge to transparent, revealing the
                // page's own background beneath, so `quickStats` — pulled up
                // to overlap it — reads as one continuous surface rather
                // than a hard seam.
                LinearGradient(colors: [.clear, Color(uiColor: .systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 170)
                    .allowsHitTesting(false)
            }
        }
    }

    private var titleRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(motorcycle.displayName)
                .font(.title.weight(.bold))
            if motorcycle.nickname?.isEmpty == false {
                Text(motorcycle.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickStats: some View {
        HStack(spacing: 10) {
            EqualInfoContainer {
                VStack(alignment: .leading, spacing: 4) {
                    Text(motorcycle.currentMileage.formatted())
                        .font(.title2.weight(.bold))
                    Text("miles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            EqualInfoContainer {
                VStack(alignment: .leading, spacing: 4) {
                    StatusBadge(status: motorcycle.overallStatus)
                    if let mostUrgentItem {
                        Text(mostUrgentItem.displayName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("Due \(mostUrgentItem.nextDueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No maintenance tracked")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// Mimics `List`'s insetGrouped card look (a plain secondary-colored
    /// header above a rounded card) by hand, now that the screen is a
    /// `ScrollView` instead of a `List`.
    @ViewBuilder
    private func sectionCard<Content: View>(_ title: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            content()
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    let motorcycle = Motorcycle(make: "Aprilia", model: "RS 660", year: 2026, currentMileage: 1200)
    motorcycle.addDefaultMaintenanceItems()
    return MotorcycleDetailView(motorcycle: motorcycle)
        .environment(AppState())
    .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}

#Preview("With Photo") {
    let motorcycle = Motorcycle(make: "Aprilia", model: "RS 660", year: 2026, currentMileage: 1200)
    motorcycle.addDefaultMaintenanceItems()
    // A tall 3:4 portrait photo, matching a typical phone camera shot, with
    // labeled horizontal bands — makes it obvious how much of the source
    // photo survives `.scaledToFill()` cropping versus getting cut off.
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 1600))
    motorcycle.photoData = renderer.pngData { context in
        let bands: [(UIColor, String)] = [
            (.systemRed, "TOP"), (.systemOrange, "2"), (.systemYellow, "3"),
            (.systemGreen, "MIDDLE"), (.systemTeal, "5"), (.systemBlue, "6"),
            (.systemPurple, "BOTTOM")
        ]
        let bandHeight = 1600 / CGFloat(bands.count)
        for (index, band) in bands.enumerated() {
            let rect = CGRect(x: 0, y: CGFloat(index) * bandHeight, width: 1200, height: bandHeight)
            band.0.setFill()
            context.fill(rect)
            let text = band.1 as NSString
            text.draw(
                at: CGPoint(x: 40, y: rect.midY - 40),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 80), .foregroundColor: UIColor.white]
            )
        }
    }
    return MotorcycleDetailView(motorcycle: motorcycle)
        .environment(AppState())
    .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}

#Preview("With Wide Photo") {
    // A wide/short (16:9-ish) landscape photo, like a trade-show floor
    // shot — this is the shape that triggers the hero's 280pt minimum
    // height clamp, which is what previously produced a letterboxed gap
    // above the photo instead of the photo reaching the very top edge.
    let motorcycle = Motorcycle(make: "Aprilia", model: "RS 660", year: 2026, currentMileage: 1200)
    motorcycle.addDefaultMaintenanceItems()
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1600, height: 900))
    motorcycle.photoData = renderer.pngData { context in
        let bands: [(UIColor, String)] = [(.systemRed, "TOP"), (.systemGreen, "MIDDLE"), (.systemBlue, "BOTTOM")]
        let bandHeight = 900 / CGFloat(bands.count)
        for (index, band) in bands.enumerated() {
            let rect = CGRect(x: 0, y: CGFloat(index) * bandHeight, width: 1600, height: bandHeight)
            band.0.setFill()
            context.fill(rect)
            (band.1 as NSString).draw(
                at: CGPoint(x: 40, y: rect.midY - 40),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 80), .foregroundColor: UIColor.white]
            )
        }
    }
    return MotorcycleDetailView(motorcycle: motorcycle)
        .environment(AppState())
    .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}

/// Separate screen for updating the odometer, reached from a row in
/// Overview rather than an inline field — keeps the detail screen's main
/// scroll focused on status/history instead of input controls.
private struct UpdateMileageView: View {
    @Bindable var motorcycle: Motorcycle
    @Environment(\.dismiss) private var dismiss
    @State private var mileageText: String = ""
    @FocusState private var isFieldFocused: Bool

    private var newMileage: Int? {
        Int(mileageText)
    }

    private var isValid: Bool {
        guard let newMileage else { return false }
        return newMileage != motorcycle.currentMileage
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Current Mileage", text: $mileageText)
                            .keyboardType(.numberPad)
                            .focused($isFieldFocused)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("This updates \(motorcycle.displayName)'s odometer and recalculates when each service is next due.")
                }
            }
            .navigationTitle("Update Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let newMileage {
                            motorcycle.currentMileage = newMileage
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                mileageText = String(motorcycle.currentMileage)
                isFieldFocused = true
            }
        }
    }
}
