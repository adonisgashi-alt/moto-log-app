//
//  AddMotorcycleView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

struct AddMotorcycleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var make: String = MotorcycleCatalog.allMakes.first ?? MotorcycleCatalog.other
    @State private var customMake: String = ""
    @State private var model: String = ""
    @State private var customModel: String = ""
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var nickname: String = ""
    @State private var currentMileage: String = ""

    private let years = Array((1980...Calendar.current.component(.year, from: Date()) + 1).reversed())

    private var resolvedMake: String {
        make == MotorcycleCatalog.other ? customMake.trimmingCharacters(in: .whitespaces) : make
    }

    private var resolvedModel: String {
        model == MotorcycleCatalog.other ? customModel.trimmingCharacters(in: .whitespaces) : model
    }

    private var isValid: Bool {
        !resolvedMake.isEmpty && !resolvedModel.isEmpty && Int(currentMileage) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Make & Model") {
                    Picker("Make", selection: $make) {
                        ForEach(MotorcycleCatalog.allMakes, id: \.self) { Text($0) }
                    }
                    .onChange(of: make) { _, _ in model = MotorcycleCatalog.modelNames(for: make).first ?? "" }

                    if make == MotorcycleCatalog.other {
                        TextField("Enter make", text: $customMake)
                    }

                    Picker("Model", selection: $model) {
                        ForEach(MotorcycleCatalog.modelNames(for: make), id: \.self) { Text($0) }
                    }

                    if model == MotorcycleCatalog.other {
                        TextField("Enter model", text: $customModel)
                    }

                    Picker("Year", selection: $year) {
                        ForEach(years, id: \.self) { Text(String($0)) }
                    }
                }

                Section("Details") {
                    TextField("Nickname (optional)", text: $nickname)
                    TextField("Current Mileage", text: $currentMileage)
                        .keyboardType(.numberPad)
                }

                Section {
                    Text(maintenanceFootnote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Motorcycle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if model.isEmpty {
                    model = MotorcycleCatalog.modelNames(for: make).first ?? ""
                }
            }
        }
    }

    private var maintenanceFootnote: String {
        if MotorcycleCatalog.info(for: resolvedMake, modelName: resolvedModel) != nil {
            return "Oil, final-drive, brake, and tire maintenance will be added automatically using \(resolvedMake)'s manufacturer-recommended intervals for this model. You can edit or remove them anytime."
        }
        return "Oil, chain, brake, and tire maintenance will be added automatically with standard intervals. You can edit or remove them anytime."
    }

    private func save() {
        guard let mileage = Int(currentMileage) else { return }
        let info = MotorcycleCatalog.info(for: resolvedMake, modelName: resolvedModel)
        let motorcycle = Motorcycle(
            make: resolvedMake,
            model: resolvedModel,
            year: year,
            nickname: nickname.trimmingCharacters(in: .whitespaces).isEmpty ? nil : nickname,
            currentMileage: mileage,
            finalDriveType: info?.finalDriveType ?? .chain
        )
        motorcycle.addDefaultMaintenanceItems(info: info)
        modelContext.insert(motorcycle)
        dismiss()
    }
}

#Preview {
    AddMotorcycleView()
        .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}
