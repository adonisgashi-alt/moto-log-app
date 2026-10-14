//
//  SafariView.swift
//  MotoLog
//

import SwiftUI
import SafariServices

/// Presents RevZilla search results in an in-app Safari sheet instead of
/// switching to the external Safari app.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
