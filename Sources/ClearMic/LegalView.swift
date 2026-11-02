import AppKit
import Foundation
import SwiftUI

enum LegalDocument: String, CaseIterable, Identifiable {
    case privacy = "Privacy policy"
    case terms = "Terms of use"
    case notices = "Third-party notices"
    case appLicense = "App license"

    var id: String { rawValue }
    var filename: String {
        switch self {
        case .privacy: "PRIVACY.md"
        case .terms: "TERMS.md"
        case .notices: "THIRD_PARTY_NOTICES.md"
        case .appLicense: "LICENSE"
        }
    }

    func contents(bundle: Bundle = .main) throws -> String {
        guard let resources = bundle.resourceURL else { throw MicError.message("App resources are unavailable.") }
        return try String(contentsOf: resources.appendingPathComponent("Legal/\(filename)"), encoding: .utf8)
    }
}

struct LegalView: View {
    @State private var document: LegalDocument = .privacy

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy and licenses").font(.title2.bold())
            Picker("Document", selection: $document) {
                ForEach(LegalDocument.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            ScrollView {
                let source = (try? document.contents()) ?? "This document is unavailable in this build. Read it in the project repository."
                let paragraphs = source.components(separatedBy: "\n\n")
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        if paragraph.hasPrefix("# ") {
                            Text(String(paragraph.dropFirst(2))).font(.title3.bold())
                        } else if paragraph.hasPrefix("## ") {
                            Text(String(paragraph.dropFirst(3))).font(.headline)
                        } else {
                            Text((try? AttributedString(markdown: paragraph,
                                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(paragraph))
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).padding(.trailing, 12)
            }.id(document)
            Divider()
            HStack {
                Button("Open all bundled license files") {
                    if let resources = Bundle.main.resourceURL {
                        NSWorkspace.shared.open(resources.appendingPathComponent("Legal/LICENSES", isDirectory: true))
                    }
                }
                Spacer()
                Link("Read on GitHub", destination: URL(string: "https://github.com/unlux/clear-mic/blob/main/\(document.filename)")!)
            }
            Link("Powered by Desert Ant Labs", destination: URL(string: "https://desertant.com")!)
                .font(.caption)
        }.padding(24).frame(minWidth: 680, minHeight: 560)
    }
}

/// Validate the actual packaged resources without opening a microphone.
func checkBundledLegalDocuments() throws {
    for document in LegalDocument.allCases {
        guard try !document.contents().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MicError.message("The bundled \(document.rawValue) is empty.")
        }
    }
    guard let resources = Bundle.main.resourceURL else { throw MicError.message("App resources are unavailable.") }
    let licenses = ["Desert-Ant-Labs-Source-Available-1.0.txt", "Desert-Ant-SDK-NOTICE.md",
                    "Desert-Ant-Third-Party-Notices.md", "Clear-Model-Third-Party-Notices.md",
                    "DeepFilterNet-MIT.txt", "Swift-Numerics-Apache-2.0.txt"]
    for filename in licenses {
        let data = try Data(contentsOf: resources.appendingPathComponent("Legal/LICENSES/\(filename)"))
        guard !data.isEmpty else { throw MicError.message("The bundled \(filename) is empty.") }
    }
    let appManifest = resources.appendingPathComponent("PrivacyInfo.xcprivacy")
    _ = try PropertyListSerialization.propertyList(from: Data(contentsOf: appManifest), format: nil)
    guard let enumerator = FileManager.default.enumerator(at: resources, includingPropertiesForKeys: nil),
          enumerator.compactMap({ $0 as? URL }).contains(where: {
              $0.lastPathComponent == "PrivacyInfo.xcprivacy" && $0.path.contains("UsagePrivacy.bundle")
          }) else {
        throw MicError.message("The SDK privacy manifest is missing from the app.")
    }
    print("Bundled privacy policy, terms, MIT license, attribution, six upstream notices and both privacy manifests passed.")
}
