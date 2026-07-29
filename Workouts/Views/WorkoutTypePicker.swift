import SwiftUI

struct WorkoutTypePicker: View {
    var workoutType: Binding<String>

    private var selectedWorkoutType: WorkoutType? {
        WorkoutType.named(workoutType.wrappedValue)
    }

    var body: some View {
        VStack {
            if let selectedWorkoutType {
                Image(systemName: selectedWorkoutType.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundColor(.accentColor)
                    .padding(.bottom)
            }

            LabeledContent("Workout Type") {
                // Wrapping the Picker in a Menu allows us to control the font used.
                Menu {
                    Picker("", selection: workoutType) {
                        ForEach(WorkoutType.all) { type in
                            Text(type.name).tag(type.name)
                        }
                    }
                } label: {
                    Text(workoutType.wrappedValue + " ")
                        .font(.title2)
                        .foregroundColor(.primary) +
                        Text(Image(systemName: "chevron.down"))
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}
