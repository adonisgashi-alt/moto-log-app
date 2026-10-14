//
//  MotorcyclePhotoView.swift
//  MotoLog
//

import SwiftUI
import PhotosUI

/// Displays a motorcycle's photo, or nothing at all when there isn't one and
/// it's not editable (the Garage list row shouldn't show a placeholder icon
/// for every bike without a photo). Hero mode (the full-bleed detail-screen
/// header) never wraps itself in its own tap target — editing there is
/// triggered by the separate `MotorcyclePhotoEditButton`, positioned by the
/// caller alongside the back button instead, so the photo itself can sit in
/// a safe-area-ignoring layer without dragging an oversized tap target (and
/// the system's full-screen Menu-preview zoom) along with it.
struct MotorcyclePhotoView: View {
    @Bindable var motorcycle: Motorcycle
    var size: CGFloat = 64
    var isEditable: Bool = false
    /// Full width with square corners instead of rounded ones, for the
    /// detail screen's full-bleed hero image rather than a size×size
    /// thumbnail. Height comes from the photo's own aspect ratio once one
    /// exists; `size` only still applies as a fixed placeholder height
    /// before a photo's been added.
    var isHero: Bool = false

    @State private var selectedItem: PhotosPickerItem?
    @State private var isShowingPhotosPicker = false
    @State private var isShowingAttribution = false

    var body: some View {
        if isHero {
            photoContent
                .overlay(alignment: .bottomTrailing) { attributionButton }
        } else if isEditable {
            ZStack(alignment: .bottomTrailing) {
                Menu {
                    pickerMenuItems
                } label: {
                    ZStack(alignment: .bottom) {
                        photoContent
                        captionPill.padding(.bottom, 8)
                    }
                }
                .buttonStyle(.plain)

                attributionButton
            }
            .photosPicker(isPresented: $isShowingPhotosPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        motorcycle.photoData = data
                        // A rider's own photo needs no attribution —
                        // only auto-fetched Commons photos carry one.
                        motorcycle.photoAttribution = nil
                        // Clearing the stale remote URL tells GarageSyncService
                        // this photo needs re-uploading.
                        motorcycle.photoURL = nil
                    }
                }
            }
        } else if motorcycle.photoData != nil {
            photoContent
        }
    }

    @ViewBuilder
    private var pickerMenuItems: some View {
        Button {
            isShowingPhotosPicker = true
        } label: {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        if motorcycle.photoData != nil {
            Button(role: .destructive) {
                motorcycle.photoData = nil
                motorcycle.photoAttribution = nil
                motorcycle.photoURL = nil
            } label: {
                Label("Remove Photo", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var attributionButton: some View {
        if let photoAttribution = motorcycle.photoAttribution {
            Button {
                isShowingAttribution = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .padding(8)
            .alert("Photo Credit", isPresented: $isShowingAttribution) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(photoAttribution)
            }
        }
    }

    private var captionPill: some View {
        Text(motorcycle.photoData == nil ? "Add Photo" : "Change Photo")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
    }

    @ViewBuilder
    private var photoContent: some View {
        if isHero, let data = motorcycle.photoData, let uiImage = UIImage(data: data) {
            // No fixed/estimated height here on purpose: anything computed
            // from `UIScreen.main.bounds.width` can drift slightly from the
            // hero's actual rendered width, and `.fit` then letterboxes a
            // thin gap at top or bottom instead of filling it exactly.
            // Driving the frame from the image's own aspect ratio lets
            // SwiftUI derive the height from the real on-screen width, so
            // there's nothing to drift. Clamped so a very wide or very tall
            // outlier photo still gets a sane-looking hero — anchored to
            // the top so a clamp-induced gap (for a wide/short photo whose
            // natural fit height is under the minimum) lands at the bottom,
            // hidden by the fade, instead of splitting a gap above the photo
            // too and cropping it away from the status bar.
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 280, maxHeight: 520, alignment: .top)
                .clipped()
        } else if let data = motorcycle.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.16, style: .continuous))
                .clipped()
        } else {
            ZStack {
                Color.secondary.opacity(0.15)
                Image(systemName: "motorcycle")
                    .font(.system(size: size * (isHero ? 0.2 : 0.4)))
                    .foregroundStyle(.secondary)
            }
            .frame(width: isHero ? nil : size, height: size)
            .frame(maxWidth: isHero ? .infinity : nil)
            .clipShape(RoundedRectangle(cornerRadius: isHero ? 0 : size * 0.16, style: .continuous))
            .clipped()
        }
    }
}

/// Small dedicated edit-photo button for the hero header, positioned by the
/// caller (alongside the back button, in a layer that respects the safe
/// area) rather than overlaid internally on the photo itself — see
/// `MotorcyclePhotoView`'s doc comment for why the two are split apart.
struct MotorcyclePhotoEditButton: View {
    @Bindable var motorcycle: Motorcycle

    @State private var selectedItem: PhotosPickerItem?
    @State private var isShowingPhotosPicker = false

    var body: some View {
        Menu {
            Button {
                isShowingPhotosPicker = true
            } label: {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
            if motorcycle.photoData != nil {
                Button(role: .destructive) {
                    motorcycle.photoData = nil
                    motorcycle.photoAttribution = nil
                    motorcycle.photoURL = nil
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: motorcycle.photoData == nil ? "photo.badge.plus" : "pencil")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }
        .photosPicker(isPresented: $isShowingPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    motorcycle.photoData = data
                    motorcycle.photoAttribution = nil
                    motorcycle.photoURL = nil
                }
            }
        }
    }
}
