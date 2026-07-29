# Workout Entry

The iOS Health app writes to and reads from a database of health information.
The data this stores includes:

- workouts (cycling, running, swimming, walking, ...)
- activity ring data
  (Move - calories burned, Exercise - minutes, and Stand - hours)
- steps
- heart rate
- resting heart rate
- body mass index (BMI)
- weight
- and much more

Many exercise-related iOS apps write to the health database.
For example, the Nike Run Club app records running workouts and
the ELEMNT cycling app (for Wahoo bike computers) records cycling workouts.
But some exercise equipment doesn't send workout data to any app.
Examples include some treadmills and spinning bikes.
In those cases, users need to manually record their workouts.
This can be done using the Health app, but the process is tedious.

The Workout Entry app simplifies adding workout data to the Health database
and displaying health data.
When users start the app for the first time,
they should grant access to reading most or all health data
and writing workout, active energy burned, and distance data.

The app is composed of three main screens.

The "Workout" screen allows users to:

- select a workout type (such as Cycling, Running, Swimming, Walking, and more)
- select the date of the workout
- select the start and end times
- enter the number of miles or kilometers covered,
  if appropriate for the workout type
- enter the number of calories burned
- add the described workout by tapping the "Add Workout" button

The "Settings" screen allows users to configure the default workout
displayed on the "Workout" screen.
For users that often repeat the same workout, this enables
adding a new workout by simply tapping the "Add Workout" button.
This screen enables selecting default values for
the workout type, units (miles or kilometers), duration (minutes),
distance (in the selected units), and calories burned.

The "Statistics" screen displays many health statistics.
It is composed of three tabs, the current year, the past 7 days, and charts.

The current year tab displays the total cycling, running, swimming,
and "walk+run" distance for the current year so far.
Sadly, the health database does not separate walking and running data.

The "Past 7 Days" tab displays the following data:

- Heart Rate Average
- Resting Heart Rate Average
- Steps per day
- Active Calories burned per day
- Basal Calories burned per day
- Total Calories burned per day

The "Charts" tab displays a chart (using Swift Charts) that contains
data for a selected health metric over a selected time span.
The time span can be 24 hours, 1 week, 1 month, or 3 months.
The chart type can be "Bar" or "Line".
The chart animates when any of its criteria is changed.
The following health metrics are supported:

- Active Energy Burned
- Distance Cycling
- Distance Walking & Running
- Environmental Audio Exposure (loud noises)
- Exercise Time
- Flights Climbed
- Headphone Audio Exposure
- Heart Rate
- Resting Energy Burned
- Resting Heart Rate
- Stair Ascent Speed
- Stair Descent Speed
- Stand Time
- Step Count
- VO2 Max
- Walking Asymmetry %
- Walking Double Support %
- Walking Speed
- Walking Step Length

I wrote this app in 2024, before LLM-assisted coding became common,
so no AI was used to create it.  It was written with Swift 5
and the latest version of Xcode at the time.
I did make minor use of the OpenAI Codex LLM to update the app
from Swift 5 to Swift 6.

The main reason I chose to use this app for my final project
is that I want to deploy it to the App Store and
the course syllabus calls for discussing deploying apps in week 8.
