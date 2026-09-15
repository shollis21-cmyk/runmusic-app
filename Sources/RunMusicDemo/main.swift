import Foundation
import RunMusicCore

let miles=5.0
let meters=miles*1609.344
let pacePerMileSeconds=9.0*60
let pacePerKilometerSeconds=pacePerMileSeconds/1.609344
let course=RaceCourse(name:"Demo 5 Mile",distanceMeters:meters,sourceURL:URL(string:"https://example.com/official-course"),sourceLabel:"Official organizer",verifiedEdition:"2026",points:[CoursePoint(distanceMeters:0,elevationMeters:20),CoursePoint(distanceMeters:2000,elevationMeters:22),CoursePoint(distanceMeters:4000,elevationMeters:78),CoursePoint(distanceMeters:6000,elevationMeters:52),CoursePoint(distanceMeters:meters,elevationMeters:35)])
let request=RunRequest(distanceMeters:meters,targetPaceSecondsPerKilometer:pacePerKilometerSeconds,intent:.steady,energyProfile:.conservativeStartStrongFinish,desiredCadenceSPM:174)
let builder=RunBuilderService(music:StaticMusicIntelligenceProvider(tracks:DemoFactory.tracks()))
let built=try await builder.build(input:BuildRunInput(request:request,manualRunnerProfile:DemoFactory.runner(),musicPreference:DemoFactory.preference(),course:course,provider:.appleMusic),activities:[])
let plan=built.playlist
func clock(_ seconds:Double)->String{let total=Int(seconds.rounded());return String(format:"%d:%02d",total/60,total%60)}
print("RunMusic end-to-end core demo")
print("5.0 miles @ 9:00/mi | target \(clock(plan.requestedDurationSeconds)) | planned \(clock(plan.plannedDurationSeconds))")
print("Objective score: \(String(format: "%.3f",plan.objectiveScore))")
print("Course-aware energy anchors: \(built.request.musicEnergyAnchors.count)")
for entry in plan.entries{let milesAtStart=entry.expectedDistanceMeters/1609.344;print("\(clock(entry.startsAtSeconds)) | mi \(String(format:"%.2f",milesAtStart)) | \(entry.track.artist) - \(entry.track.title) | score \(String(format:"%.2f",entry.score))")}
print("\nMile markers")
for marker in plan.markers{print("Mile \(marker.milestoneNumber): nearest \(marker.nearestTrackID), timing error \(Int(marker.timingErrorSeconds.rounded()))s")}
