//
//  FileUploadManager.swift
//  tawazon
//

import Foundation
import UniformTypeIdentifiers

final class FileUploadManager {
    static let shared = FileUploadManager()

    private let api = APIService.shared
    private let keychain = KeychainService.shared

    private init() {}

    /// Uploads file data via presigned URL; returns the storage key from the presign response.
    func uploadFile(
        data: Data,
        filename: String,
        contentType: String,
        token: String
    ) async throws -> String {
        let presign = try await api.getPresignedUploadUrl(
            PresignedUploadRequest(filename: filename, contentType: contentType),
            token: token
        )
        guard let url = URL(string: presign.uploadUrl) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        return presign.storageKey
    }

    static func mimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension),
           let mime = type.preferredMIMEType {
            return mime
        }
        return "application/octet-stream"
    }
}
