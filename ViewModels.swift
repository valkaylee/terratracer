import SwiftUI
import AVKit
import Combine

class TerraTracerViewModel: ObservableObject {
  @Published var flightSamples: [FlightSample] = []
  @Published var detectionEvents: [DetectionEvent] = []
  @Published var currentFlightIndex = 0
  @Published var seenDetections: [DetectionEvent] = []
  @Published var isAlienDetectedNow: Bool = false
  @Published var isPlaying = false

  let player: AVPlayer
  private var timerCancellable: AnyCancellable?
  private var startDate: Date?

  init() {
    flightSamples = Self.loadFlightCSV("flight_data")
    detectionEvents = Self.loadDetectionCSV("alien_detection")
    
    guard let url = Bundle.main.url(forResource: "drone_video", withExtension: "mp4") else {
      fatalError("Missing drone_video.mp4 in bundle")
    }
    player = AVPlayer(url: url)
    
    // Call debug prints after all properties are initialized
    printDetections()
  }

  private static func loadFlightCSV(_ name: String) -> [FlightSample] {
    guard let url = Bundle.main.url(forResource: name, withExtension: "csv"),
          let text = try? String(contentsOf: url, encoding: .utf8) else {
      fatalError("Could not load \(name).csv")
    }
    
    // Skip header row
    let lines = text.split(separator: "\n")
    guard lines.count > 1 else { return [] }
    
    return lines.dropFirst().compactMap { line in
      let c = line.split(separator: ",")
      guard c.count >= 5,
            let timeMs = Double(c[0]),
            let heightTakeoff = Double(c[3]),
            let zSpeed = Double(c[4]) else { return nil }
      
      // Extract dateTimeUTC and flyState
      let dateTimeUTC = c.count > 1 ? String(c[1]) : ""
      let flyState = c.count > 5 ? String(c[5]) : ""
      
      return FlightSample(
        timeMs: timeMs,
        dateTimeUTC: dateTimeUTC,
        heightTakeoff: heightTakeoff,
        zSpeed: zSpeed,
        flyState: flyState
      )
    }
  }

  private static func loadDetectionCSV(_ name: String) -> [DetectionEvent] {
    print("Attempting to load \(name).csv")
    
    guard let url = Bundle.main.url(forResource: name, withExtension: "csv") else {
      print("Error: Could not find \(name).csv in bundle")
      return []
    }
    
    print("Found CSV at: \(url.path)")
    
    guard let text = try? String(contentsOf: url, encoding: .utf8) else {
      print("Error: Could not read contents of \(name).csv")
      return []
    }
    
    print("Successfully read CSV contents")
    print("CSV contents: \(text)")
    
    // Split by both \n and \r\n to handle different line endings
    let lines = text.components(separatedBy: .newlines)
        .filter { !$0.isEmpty }  // Remove empty lines
    
    guard !lines.isEmpty else {
      print("Error: CSV is empty")
      return []
    }
    
    print("Found \(lines.count) lines in CSV")
    
    let events: [DetectionEvent] = lines.compactMap { line -> DetectionEvent? in
      let c = line.split(separator: ",")
      guard c.count >= 7,
            let timeMs = Double(c[0]),
            let probability = Double(c[3]),
            let x = Double(c[4]),
            let y = Double(c[5]),
            let width = Double(c[6]),
            let height = c.count > 7 ? Double(c[7]) : 0 else {
        print("Error parsing line: \(line)")
        return nil
      }
            
      let timestamp = String(c[1])
      let label = String(c[2])
      
      let description = String(format: "%d, %@, %@, %.0f%%, %.0f, %.0f, %.0f, %.0f",
                             Int(timeMs),
                             timestamp,
                             label,
                             probability * 100,
                             x, y, width, height)
      
      return DetectionEvent(
        timeMs: timeMs,
        timestamp: timestamp,
        label: label,
        probability: probability,
        x: x,
        y: y,
        width: width,
        height: height,
        description: description
      )
    }
    
    print("Successfully parsed \(events.count) detection events")
    return events
  }

  private func printDetections() {
    print("Loaded \(detectionEvents.count) detection events")
    for event in detectionEvents {
      print("Detection at \(event.timeMs)ms: \(event.description)")
    }
  }

  func start() {
    guard !isPlaying else { return }
    isPlaying = true
    currentFlightIndex = 0
    seenDetections.removeAll()
    isAlienDetectedNow = false
    startDate = Date()
    player.seek(to: .zero)
    player.play()
    timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in self?.tick() }
  }

  func stop() {
    isPlaying = false
    timerCancellable?.cancel()
    player.pause()
  }

  private func tick() {
    guard let start = startDate else { return }
    let elapsed = Date().timeIntervalSince(start) * 1_000
    
    // Find the appropriate flight sample index
    if let next = flightSamples.firstIndex(where: { $0.timeMs > elapsed }) {
      currentFlightIndex = next - 1
    } else if !flightSamples.isEmpty {
      // If we've reached the end, use the last sample
      currentFlightIndex = flightSamples.count - 1
    } else {
      // If no samples, reset to 0
      currentFlightIndex = 0
    }
    
    // Ensure currentFlightIndex is within bounds
    currentFlightIndex = max(0, min(currentFlightIndex, flightSamples.count - 1))
    
    // Check if there are any active detections at current time
    let timeWindow: Double = 300 // 300ms window to show alien as detected
    isAlienDetectedNow = detectionEvents.contains { detection in
      (elapsed - timeWindow...elapsed + timeWindow).contains(detection.timeMs)
    }
    
    let newDetections = detectionEvents.filter { detection in
      // Add a small buffer (50ms) to account for timer granularity
      let shouldDetect = detection.timeMs <= elapsed + 50 &&
        !seenDetections.contains(where: { seen in seen.id == detection.id })
      
      if shouldDetect {
        print("Detection at \(detection.timeMs)ms: \(detection.description)")
      }
      
      return shouldDetect
    }
    
    if !newDetections.isEmpty {
      DispatchQueue.main.async {
        self.seenDetections.append(contentsOf: newDetections)
        print("Added \(newDetections.count) new detections. Total: \(self.seenDetections.count)")
      }
    }
  }
}
