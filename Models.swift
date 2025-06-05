import Foundation

struct FlightSample: Identifiable {
    let id = UUID()
    let timeMs: Double             // time(millisecond)
    let dateTimeUTC: String        // datetime(utc)
    let heightTakeoff: Double      // height_above_takeoff(feet)
    let zSpeed: Double             // zSpeed(mph)
    let flyState: String           // flyState
}

struct DetectionEvent: Identifiable {
    let id = UUID()
    let timeMs: Double
    let timestamp: String
    let label: String
    let probability: Double
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let description: String
}
