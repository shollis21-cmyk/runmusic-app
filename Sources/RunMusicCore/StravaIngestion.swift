import Foundation

public protocol CanonicalActivityStoring: Sendable { @discardableResult func upsert(_ activities:[CanonicalActivity]) async throws->Int; func allActivities() async throws->[CanonicalActivity] }
public actor InMemoryCanonicalActivityStore: CanonicalActivityStoring {
    private var activities:[CanonicalActivity]=[]; public init(){}
    public func upsert(_ newActivities:[CanonicalActivity])->Int{var changed=0;for activity in newActivities{let providerID=activity.sourceActivityIDs[activity.primarySource];if let index=activities.firstIndex(where:{$0.primarySource==activity.primarySource && $0.sourceActivityIDs[$0.primarySource]==providerID}){if activities[index] != activity{activities[index]=activity;changed+=1}}else{activities.append(activity);changed+=1}};activities.sort{$0.startedAt>$1.startedAt};return changed}
    public func allActivities()->[CanonicalActivity]{activities}
}
public struct StravaBackgroundIngestionService: Sendable {
    private let historyClient:StravaHistoryClient;private let oauthSession:OAuthSession;private let syncCoordinator:RateLimitAwareBackgroundSyncCoordinator;private let activityStore:any CanonicalActivityStoring;private let maximumEnrichedActivities:Int
    public init(historyClient:StravaHistoryClient,oauthSession:OAuthSession,syncCoordinator:RateLimitAwareBackgroundSyncCoordinator,activityStore:any CanonicalActivityStoring,maximumEnrichedActivities:Int=20){self.historyClient=historyClient;self.oauthSession=oauthSession;self.syncCoordinator=syncCoordinator;self.activityStore=activityStore;self.maximumEnrichedActivities=max(0,maximumEnrichedActivities)}
    public func sync(now:Date=Date()) async throws->BackgroundSyncResult{try await syncCoordinator.sync(provider:"strava",now:now){cursor in let tokens=try await oauthSession.validTokens(now:now);let after=cursor.flatMap(TimeInterval.init).map(Date.init(timeIntervalSince1970:));let external=try await historyClient.fetchEnrichedActivities(after:after,accessToken:tokens.accessToken,maximumEnrichedActivities:maximumEnrichedActivities);let canonical=external.map{ExternalActivityMapper.canonicalize($0)};let changed=try await activityStore.upsert(canonical);let newest=external.map(\.startedAt).max();let nextCursor=newest.map{String($0.timeIntervalSince1970)} ?? cursor;return ProviderSyncPage(nextCursor:nextCursor,importedItemCount:changed)}}
}
