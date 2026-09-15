import Foundation

public enum UserDataCategory: String, Codable, Sendable, CaseIterable { case profile, activities, musicPreferences, observations, racePlans, connectionMetadata }
public struct UserDataExportManifest: Codable, Sendable, Equatable {
    public let generatedAt: Date
    public let categories: [UserDataCategory]
    public let schemaVersion: Int
    public init(generatedAt: Date = Date(), categories: [UserDataCategory], schemaVersion: Int = 1) { self.generatedAt=generatedAt; self.categories=categories; self.schemaVersion=schemaVersion }
}
public protocol UserDataManaging: Sendable {
    func exportManifest() async throws -> UserDataExportManifest
    func delete(categories: Set<UserDataCategory>) async throws
}
