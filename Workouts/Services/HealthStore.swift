import HealthKit

// swiftlint:disable type_body_length
class HealthStore {
    private static let zeroFilledQuantityTypes: Set<HKQuantityTypeIdentifier> = [
        .distanceCycling, .distanceWalkingRunning, .distanceWheelchair,
        .pushCount, .stepCount
    ]

    // This assumes that HKHealthStore.isHealthDataAvailable()
    // has already been checked.
    private var store = HKHealthStore()

    func addWorkout(
        workoutType: String,
        startTime: Date,
        endTime: Date,
        distance: Double,
        calories: Int
    ) async throws {
        guard let workoutType = WorkoutType.named(workoutType) else {
            throw AppError(message: "no workout type found for \(workoutType)")
        }

        let energyBurnedType =
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energyBurnedQuantity = HKQuantity(
            unit: .largeCalorie(),
            doubleValue: Double(calories)
        )
        let energySample = HKQuantitySample(
            type: energyBurnedType,
            quantity: energyBurnedQuantity,
            start: startTime,
            end: endTime
        )
        var samples: [HKSample] = [energySample]

        var distanceQuantity: HKQuantity?

        if let identifier = workoutType.distanceIdentifier {
            let distanceType =
                HKObjectType.quantityType(forIdentifier: identifier)!
            let preferKM =
                UserDefaults.standard.bool(forKey: "preferKilometers")
            let unit: HKUnit = preferKM ? HKUnit.meter() : HKUnit.mile()
            let unitDistance = preferKM ? distance * 1000 : distance
            distanceQuantity = HKQuantity(
                unit: unit,
                doubleValue: unitDistance
            )

            let distanceSample = HKQuantitySample(
                type: distanceType,
                quantity: distanceQuantity!,
                start: startTime,
                end: endTime
            )
            samples.append(distanceSample)
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType.activityType

        let workoutBuilder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: nil
        )
        try await workoutBuilder.beginCollection(at: startTime)
        try await workoutBuilder.addSamples(samples)
        try await workoutBuilder.endCollection(at: endTime)
        try await workoutBuilder.finishWorkout()
    }

    private func addZeros(
        datedValues: inout [DatedValue],
        frequency: Frequency? = nil
    ) {
        for index in 0 ..< datedValues.count - 1 {
            let current = datedValues[index]
            let next = datedValues[index + 1]
            let currentDate = Date.from(ms: current.ms)
            let nextDate = Date.from(ms: next.ms)

            if frequency == .hour {
                let missing = currentDate.hoursBetween(date: nextDate) - 1
                if missing > 0 {
                    for delta in 1 ... missing {
                        let date = currentDate.hoursAfter(delta)
                        let datedValue = DatedValue(
                            date: date.ymdh,
                            ms: date.milliseconds,
                            unit: current.unit,
                            value: 0.0
                        )
                        datedValues.insert(datedValue, at: index + delta)
                    }
                }
            } else if frequency == .day {
                let missing = currentDate.daysBetween(date: nextDate) - 1
                if missing > 0 {
                    for delta in 1 ... missing {
                        let date = currentDate.daysAfter(delta)
                        let datedValue = DatedValue(
                            date: date.ymd,
                            ms: date.milliseconds,
                            unit: current.unit,
                            value: 0.0
                        )
                        datedValues.insert(datedValue, at: index + delta)
                    }
                }
            }
        }
    }

    func average(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async throws -> Double {
        try await withCheckedThrowingContinuation { completion in
            let quantityType = HKQuantityType.quantityType(
                forIdentifier: identifier
            )!
            let predicate: NSPredicate? = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate
            )
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { (_: HKStatisticsQuery, result: HKStatistics?, error: Error?) in
                if let error {
                    completion.resume(throwing: error)
                } else {
                    let quantity: HKQuantity? = result?.averageQuantity()
                    let result = quantity?.doubleValue(for: unit)
                    completion.resume(returning: result ?? 0)
                }
            }
            store.execute(query)
        }
    }

    private func categoryType(
        _ typeId: HKCategoryTypeIdentifier
    ) -> HKCategoryType {
        HKCategoryType.categoryType(forIdentifier: typeId)!
    }

    private func characteristicType(
        _ typeId: HKCharacteristicTypeIdentifier
    ) -> HKCharacteristicType {
        HKCharacteristicType.characteristicType(forIdentifier: typeId)!
    }

    private func dateRangePredicate(
        startDate: Date,
        endDate: Date?
    ) -> NSPredicate {
        HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
    }

    // Gets specific data from HealthKit.
    // swiftlint:disable function_body_length
    func getData(
        identifier: HKQuantityTypeIdentifier,
        startDate: Date? = nil,
        endDate: Date? = nil,
        frequency: Frequency? = nil
    ) async throws -> [DatedValue] {
        guard let metric = Metrics.shared.map[identifier] else {
            throw AppError(message: "metric \(identifier.rawValue) not found")
        }

        let frequencyToUse = frequency ?? metric.frequency

        let interval =
            frequencyToUse == .minute ? DateComponents(minute: 1) :
            frequencyToUse == .hour ? DateComponents(hour: 1) :
            frequencyToUse == .day ? DateComponents(day: 1) :
            frequencyToUse == .week ? DateComponents(day: 7) :
            DateComponents(day: 1)

        let collection = try await queryQuantityCollection(
            typeId: metric.identifier,
            options: metric.option,
            startDate: startDate,
            endDate: endDate,
            interval: interval
        )

        var datedValues = collection.map { data -> DatedValue in
            let date = data.startDate
            let quantity = metric.option == .cumulativeSum ?
                data.sumQuantity() :
                data.averageQuantity()
            let value = quantity?.doubleValue(for: metric.unit) ?? 0
            return DatedValue(
                date: frequencyToUse == .day ? date.ymd : date.ymdh,
                ms: date.milliseconds,
                unit: metric.unit.unitString,
                value: value
            )
        }

        if !datedValues.isEmpty,
           Self.zeroFilledQuantityTypes.contains(identifier) {
            addZeros(datedValues: &datedValues, frequency: frequency)
        }

        return datedValues
    }

    private func quantityType(
        _ typeId: HKQuantityTypeIdentifier
    ) -> HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: typeId)!
    }

    func queryQuantityCollection(
        typeId: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions,
        startDate: Date? = nil,
        endDate: Date? = nil,
        interval: DateComponents? = nil
    ) async throws -> [HKStatistics] {
        // Default end date is today.
        let end = endDate ?? Date()

        // Default start date is seven days before the end date.
        let start = startDate ?? end.daysBefore(7)

        // Default interval is one day.
        let intervalComponents = interval ?? DateComponents(day: 1)

        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType(typeId),
            quantitySamplePredicate: dateRangePredicate(
                startDate: start,
                endDate: end
            ),
            options: options,
            anchorDate: Date.mondayAt12AM(), // defined in DateExtensions.swift
            intervalComponents: intervalComponents
        )
        return try await withCheckedThrowingContinuation { continuation in
            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let collection = collection {
                    continuation.resume(returning: collection.statistics())
                } else {
                    Log.error("No \(typeId) data was found.")
                    continuation.resume(returning: [HKStatistics]())
                }
            }
            store.execute(query)
        }
    }

    func runningMiles(startDate: Date, endDate: Date) async throws -> Double {
        let workoutDate = HKQuery.predicateForWorkoutActivities(
            start: startDate,
            end: endDate
        )
        let workouts = HKQuery.predicateForWorkouts(
            activityPredicate: workoutDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: workouts,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: 0)
                    return
                }

                let quantityType = HKQuantityType(.distanceWalkingRunning)
                let miles = workouts.reduce(0.0) { total, workout in
                    guard workout.workoutActivityType == .running,
                          let distance = workout.statistics(for: quantityType)?
                          .sumQuantity() else {
                        return total
                    }
                    return total + distance.doubleValue(for: .mile())
                }
                continuation.resume(returning: miles)
            }

            store.execute(query)
        }
    }

    // swiftlint:disable function_body_length
    func requestAuthorization() async {
        do {
            // Request permission from the user to access HealthKit data.
            // If they have already granted permission,
            // they will not be prompted again.

            // This throws if authorization could not be requested.
            // Not throwing is not an indication that the user
            // granted all the requested permissions.
            try await store.requestAuthorization(
                // The app can update these.
                toShare: [
                    quantityType(.activeEnergyBurned),
                    quantityType(.distanceCycling),
                    // quantityType(.distanceDownhillSnowSports),
                    quantityType(.distanceSwimming),
                    quantityType(.distanceWalkingRunning),
                    HKObjectType.workoutType()
                ],
                // The app can read these.
                read: [
                    .activitySummaryType(),
                    .workoutType(),

                    // It seems there is both appleStandHour and appleStandHours.
                    // Are these just two names for the same thing?
                    categoryType(.appleStandHour),

                    characteristicType(.activityMoveMode),
                    characteristicType(.wheelchairUse),

                    quantityType(.activeEnergyBurned),
                    quantityType(.appleExerciseTime),
                    quantityType(.appleStandTime),
                    quantityType(.basalEnergyBurned),

                    quantityType(.distanceCycling),
                    // quantityType(.distanceDownhillSnowSports),
                    quantityType(.distanceSwimming),
                    quantityType(.distanceWalkingRunning),

                    // Not getting data due to not using wheelchair
                    // and not enabling wheelchair mode.
                    quantityType(.distanceWheelchair),

                    quantityType(.environmentalAudioExposure),

                    quantityType(.flightsClimbed),
                    quantityType(.headphoneAudioExposure),
                    quantityType(.heartRate),

                    // Not getting data due to not using wheelchair
                    // and not enabling wheelchair mode.
                    quantityType(.pushCount),

                    // This is breaths per day.
                    quantityType(.respiratoryRate),

                    // This only provides one number per day.
                    quantityType(.restingHeartRate),

                    quantityType(.stairAscentSpeed),
                    quantityType(.stairDescentSpeed),
                    quantityType(.stepCount),

                    // I don't get any data because I haven't been swimming.
                    quantityType(.swimmingStrokeCount),

                    // In the Health app, this appears under "Cardio Fitness".
                    quantityType(.vo2Max),

                    quantityType(.walkingAsymmetryPercentage),
                    quantityType(.walkingDoubleSupportPercentage),
                    quantityType(.walkingSpeed),
                    quantityType(.walkingStepLength)
                ]
            )
        } catch {
            Log.error(error)
        }
    }

    func sum(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async throws -> Double {
        try await withCheckedThrowingContinuation { completion in
            let quantityType = HKQuantityType.quantityType(
                forIdentifier: identifier
            )!
            let predicate: NSPredicate? = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate
            )
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { (_: HKStatisticsQuery, result: HKStatistics?, error: Error?) in
                if let error {
                    if error.localizedDescription
                        .starts(with: "No data available") {
                        completion.resume(returning: 0)
                    } else {
                        completion.resume(throwing: error)
                    }
                } else {
                    let quantity: HKQuantity? = result?.sumQuantity()
                    let result = quantity?.doubleValue(for: unit)
                    completion.resume(returning: result ?? 0)
                }
            }
            store.execute(query)
        }
    }

    // enum with values notSet(0), no(1), and yes(2)
    func wheelchairUse() throws -> HKWheelchairUse {
        try store.wheelchairUse().wheelchairUse
    }
}
