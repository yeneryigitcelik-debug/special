// This file is deprecated. Use APIClient.swift + TokenManager.swift instead.
// Kept as a stub to prevent build errors during migration.
// TODO: Remove this file after full migration is verified.

import Foundation

@available(*, deprecated, message: "Use APIClient.shared instead")
final class SupabaseManager {
    static let shared = SupabaseManager()
    private init() {}
}
