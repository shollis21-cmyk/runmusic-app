import Foundation

public enum DataSource: String, Codable, Sendable, CaseIterable {
    case manual, appleHealth, appleWatch, strava, garmin, nikeRunClub, importedFile
}

public enum MusicProvider: String, Codable, Sendable, CaseIterable {
    case appleMusic, spotify, amazonMusic, manual
}

public enum WorkoutIntent: String, Codable, Sendable, CaseIterable {
    case easy, recovery, steady, tempo, intervals, longRun, race, custom
}

public enum EnergyProfile: String, Codable, Sendable, CaseIterable {
    case steady, progressive, negativeSplit, conservativeStartStrongFinish
}

public struct ProvenancedValue<Value: Codable & Sendable & Equatable>: Codable, Sendable, Equatable {
    public let value: Value
    public let source: DataSource
    public let confidence: Double
    public let capturedAt: Date?
    public init(value: Value, source: DataSource, confidence: Double, capturedAt: Date? = nil) { self.value = value; self.source = source; self.confidence = min(max(confidence, 0), 1); self.capturedAt = capturedAt }
}

public struct ActivitySample: Codable, Sendable, Equatable {
    public let elapsedSeconds: TimeInterval; public let distanceMeters: Double; public let paceSecondsPerKilometer: Double?; public let heartRateBPM: Double?; public let cadenceSPM: Double?; public let powerWatts: Double?; public let elevationMeters: Double?
    public init(elapsedSeconds: TimeInterval, distanceMeters: Double, paceSecondsPerKilometer: Double? = nil, heartRateBPM: Double? = nil, cadenceSPM: Double? = nil, powerWatts: Double? = nil, elevationMeters: Double? = nil) { self.elapsedSeconds=elapsedSeconds; self.distanceMeters=distanceMeters; self.paceSecondsPerKilometer=paceSecondsPerKilometer; self.heartRateBPM=heartRateBPM; self.cadenceSPM=cadenceSPM; self.powerWatts=powerWatts; self.elevationMeters=elevationMeters }
}

public struct CanonicalActivity: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID; public let startedAt: Date; public let durationSeconds: TimeInterval; public let distanceMeters: Double; public let primarySource: DataSource; public let sourceActivityIDs: [DataSource:String]; public let averagePaceSecondsPerKilometer: ProvenancedValue<Double>?; public let averageHeartRateBPM: ProvenancedValue<Double>?; public let averageCadenceSPM: ProvenancedValue<Double>?; public let averagePowerWatts: ProvenancedValue<Double>?; public let strideLengthMeters: ProvenancedValue<Double>?; public let groundContactTimeMilliseconds: ProvenancedValue<Double>?; public let verticalOscillationCentimeters: ProvenancedValue<Double>?; public let samples: [ActivitySample]
    public init(id: UUID = UUID(), startedAt: Date, durationSeconds: TimeInterval, distanceMeters: Double, primarySource: DataSource, sourceActivityIDs: [DataSource:String] = [:], averagePaceSecondsPerKilometer: ProvenancedValue<Double>? = nil, averageHeartRateBPM: ProvenancedValue<Double>? = nil, averageCadenceSPM: ProvenancedValue<Double>? = nil, averagePowerWatts: ProvenancedValue<Double>? = nil, strideLengthMeters: ProvenancedValue<Double>? = nil, groundContactTimeMilliseconds: ProvenancedValue<Double>? = nil, verticalOscillationCentimeters: ProvenancedValue<Double>? = nil, samples: [ActivitySample] = []) { self.id=id; self.startedAt=startedAt; self.durationSeconds=durationSeconds; self.distanceMeters=distanceMeters; self.primarySource=primarySource; self.sourceActivityIDs=sourceActivityIDs; self.averagePaceSecondsPerKilometer=averagePaceSecondsPerKilometer; self.averageHeartRateBPM=averageHeartRateBPM; self.averageCadenceSPM=averageCadenceSPM; self.averagePowerWatts=averagePowerWatts; self.strideLengthMeters=strideLengthMeters; self.groundContactTimeMilliseconds=groundContactTimeMilliseconds; self.verticalOscillationCentimeters=verticalOscillationCentimeters; self.samples=samples }
}

public struct RunnerProfile: Codable, Sendable, Equatable {
    public var preferredUnitsMiles: Bool; public var easyPaceSecondsPerKilometer: Double?; public var thresholdPaceSecondsPerKilometer: Double?; public var typicalCadenceSPM: Double?; public var typicalPowerWatts: Double?; public var maxHeartRateBPM: Double?; public var dataConfidence: Double; public var historyActivityCount: Int
    public init(preferredUnitsMiles: Bool = true, easyPaceSecondsPerKilometer: Double? = nil, thresholdPaceSecondsPerKilometer: Double? = nil, typicalCadenceSPM: Double? = nil, typicalPowerWatts: Double? = nil, maxHeartRateBPM: Double? = nil, dataConfidence: Double = 0, historyActivityCount: Int = 0) { self.preferredUnitsMiles=preferredUnitsMiles; self.easyPaceSecondsPerKilometer=easyPaceSecondsPerKilometer; self.thresholdPaceSecondsPerKilometer=thresholdPaceSecondsPerKilometer; self.typicalCadenceSPM=typicalCadenceSPM; self.typicalPowerWatts=typicalPowerWatts; self.maxHeartRateBPM=maxHeartRateBPM; self.dataConfidence=min(max(dataConfidence,0),1); self.historyActivityCount=max(historyActivityCount,0) }
}

public struct MusicPreference: Codable, Sendable, Equatable {
    public var favoriteArtists:[String]; public var preferredGenres:[String]; public var dislikedArtists:[String]; public var explicitContentAllowed:Bool; public var preferenceConfidence:Double
    public init(favoriteArtists:[String]=[], preferredGenres:[String]=[], dislikedArtists:[String]=[], explicitContentAllowed:Bool=true, preferenceConfidence:Double=0) { self.favoriteArtists=favoriteArtists; self.preferredGenres=preferredGenres; self.dislikedArtists=dislikedArtists; self.explicitContentAllowed=explicitContentAllowed; self.preferenceConfidence=min(max(preferenceConfidence,0),1) }
}

public struct MusicTrack: Codable, Sendable, Equatable, Identifiable {
    public let id:String; public let isrc:String?; public let title:String; public let artist:String; public let durationSeconds:TimeInterval; public let bpm:Double?; public let energy:Double?; public let familiarity:Double; public let preferenceScore:Double; public let explicit:Bool; public let providerIDs:[MusicProvider:String]
    public init(id:String, isrc:String?=nil, title:String, artist:String, durationSeconds:TimeInterval, bpm:Double?=nil, energy:Double?=nil, familiarity:Double=0.5, preferenceScore:Double=0.5, explicit:Bool=false, providerIDs:[MusicProvider:String]=[:]) { self.id=id; self.isrc=isrc; self.title=title; self.artist=artist; self.durationSeconds=max(durationSeconds,1); self.bpm=bpm; self.energy=energy.map{min(max($0,0),1)}; self.familiarity=min(max(familiarity,0),1); self.preferenceScore=min(max(preferenceScore,0),1); self.explicit=explicit; self.providerIDs=providerIDs }
}

public struct RunRequest: Codable, Sendable, Equatable {
    public let distanceMeters:Double; public let targetPaceSecondsPerKilometer:Double; public let intent:WorkoutIntent; public let energyProfile:EnergyProfile; public let desiredCadenceSPM:Double?; public let milestoneDistanceMeters:Double; public let musicEnergyAnchors:[EnergyAnchor]
    public init(distanceMeters:Double, targetPaceSecondsPerKilometer:Double, intent:WorkoutIntent=.steady, energyProfile:EnergyProfile=.steady, desiredCadenceSPM:Double?=nil, milestoneDistanceMeters:Double=1609.344, musicEnergyAnchors:[EnergyAnchor]=[]) { self.distanceMeters=max(distanceMeters,1); self.targetPaceSecondsPerKilometer=max(targetPaceSecondsPerKilometer,1); self.intent=intent; self.energyProfile=energyProfile; self.desiredCadenceSPM=desiredCadenceSPM; self.milestoneDistanceMeters=max(milestoneDistanceMeters,100); self.musicEnergyAnchors=musicEnergyAnchors.sorted{$0.distanceMeters<$1.distanceMeters} }
    public var targetDurationSeconds: TimeInterval { distanceMeters / 1000 * targetPaceSecondsPerKilometer }
}

public struct PlaylistEntry: Codable, Sendable, Equatable { public let track:MusicTrack; public let startsAtSeconds:TimeInterval; public let expectedDistanceMeters:Double; public let score:Double; public let reasons:[String] }
public struct MileMarker: Codable, Sendable, Equatable { public let milestoneNumber:Int; public let targetDistanceMeters:Double; public let targetTimeSeconds:TimeInterval; public let nearestTrackID:String; public let timingErrorSeconds:TimeInterval }
public struct PlaylistPlan: Codable, Sendable, Equatable { public let requestedDurationSeconds:TimeInterval; public let plannedDurationSeconds:TimeInterval; public let entries:[PlaylistEntry]; public let markers:[MileMarker]; public let objectiveScore:Double }
