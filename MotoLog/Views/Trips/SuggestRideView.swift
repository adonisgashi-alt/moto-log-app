//
//  SuggestRideView.swift
//  MotoLog
//

import SwiftUI

struct SuggestRideView: View {
    @Environment(RouteSuggestionService.self) private var routeSuggestion
    @Environment(\.dismiss) private var dismiss

    private enum GoalType: String, CaseIterable {
        case miles = "Miles"
        case hours = "Hours"
    }

    @State private var goalType: GoalType = .miles
    @State private var milesValue: Double = 50
    @State private var hoursValue: Double = 1.5
    @State private var roadType: RoadType = .scenic
    @State private var isShowingResults = false

    private var goal: RideGoal {
        switch goalType {
        case .miles: return .miles(milesValue)
        case .hours: return .hours(hoursValue)
        }
    }

    private var hoursLabel: String {
        let wholeHours = Int(hoursValue)
        let minutes = Int((hoursValue - Double(wholeHours)) * 60)
        return minutes == 0 ? "\(wholeHours)h" : "\(wholeHours)h \(minutes)m"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ride Length") {
                    Picker("Set up by", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)

                    if goalType == .miles {
                        Stepper(value: $milesValue, in: 10...300, step: 5) {
                            LabeledContent("Distance", value: "\(Int(milesValue)) mi")
                        }
                    } else {
                        Stepper(value: $hoursValue, in: 0.5...8, step: 0.5) {
                            LabeledContent("Duration", value: hoursLabel)
                        }
                    }
                }

                Section {
                    Picker("Road Type", selection: $roadType) {
                        ForEach(RoadType.allCases) { type in
                            Label(type.displayName, systemImage: type.systemImage).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Road Type")
                } footer: {
                    Text("Curvy and Scenic favor parks, overlooks, and rural roads near you. City favors downtown and commercial areas. MapKit doesn't expose true road-curvature data, so this is a best-effort route, not a guaranteed twisty backroad.")
                }

                if let errorMessage = routeSuggestion.errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Suggest a Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(routeSuggestion.isSearching ? "Finding..." : "Find Routes") {
                        Task {
                            await routeSuggestion.suggestRoutes(goal: goal, roadType: roadType)
                            if !routeSuggestion.suggestedRoutes.isEmpty {
                                isShowingResults = true
                            }
                        }
                    }
                    .disabled(routeSuggestion.isSearching)
                }
            }
            .sheet(isPresented: $isShowingResults) {
                SuggestedRoutesResultView()
            }
        }
    }
}
