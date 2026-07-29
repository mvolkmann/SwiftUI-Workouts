import HealthKit

struct WorkoutType: Hashable, Identifiable, Sendable {
    let name: String
    let activityType: HKWorkoutActivityType
    let symbolName: String
    let distanceIdentifier: HKQuantityTypeIdentifier?

    var id: String { name }
    var tracksDistance: Bool { distanceIdentifier != nil }

    static let all: [WorkoutType] = [
        WorkoutType(name: "Boxing", activityType: .boxing, symbolName: "figure.boxing"),
        WorkoutType(name: "Climbing", activityType: .climbing, symbolName: "figure.climbing"),
        WorkoutType(name: "Cycling", activityType: .cycling, symbolName: "figure.outdoor.cycle", distanceIdentifier: .distanceCycling),
        WorkoutType(name: "Elliptical", activityType: .elliptical, symbolName: "figure.elliptical"),
        WorkoutType(name: "Hiking", activityType: .hiking, symbolName: "figure.hiking", distanceIdentifier: .distanceWalkingRunning),
        WorkoutType(name: "Kickboxing", activityType: .kickboxing, symbolName: "figure.kickboxing"),
        WorkoutType(name: "Pilates", activityType: .pilates, symbolName: "figure.pilates"),
        WorkoutType(name: "Rowing", activityType: .rowing, symbolName: "figure.rower"),
        WorkoutType(name: "Running", activityType: .running, symbolName: "figure.run", distanceIdentifier: .distanceWalkingRunning),
        WorkoutType(name: "Skating Sports", activityType: .skatingSports, symbolName: "figure.skating"),
        WorkoutType(name: "Stairs", activityType: .stairs, symbolName: "figure.stairs"),
        WorkoutType(name: "Swimming", activityType: .swimming, symbolName: "figure.pool.swim", distanceIdentifier: .distanceSwimming),
        WorkoutType(name: "Yoga", activityType: .yoga, symbolName: "figure.yoga"),
        WorkoutType(name: "Walking", activityType: .walking, symbolName: "figure.walk", distanceIdentifier: .distanceWalkingRunning)
    ]

    init(
        name: String,
        activityType: HKWorkoutActivityType,
        symbolName: String,
        distanceIdentifier: HKQuantityTypeIdentifier? = nil
    ) {
        self.name = name
        self.activityType = activityType
        self.symbolName = symbolName
        self.distanceIdentifier = distanceIdentifier
    }

    static func named(_ name: String) -> WorkoutType? {
        all.first { $0.name == name }
    }
}
