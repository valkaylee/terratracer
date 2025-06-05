import SwiftUI
import AVKit

struct ContentView: View {
    @ObservedObject var vm: TerraTracerViewModel
    @State private var showPointCloud = false

    init(vm: TerraTracerViewModel = TerraTracerViewModel()) {
        self.vm = vm
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    // Top: Drones and Title
                    HStack {
                        Image("white_drone")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .padding(.leading, 20)

                        Spacer()

                        Text("TerraTracer")
                            .font(.custom("KafericeFindlandia", size: 80))
                            .foregroundColor(.white)
                            .bold()

                        Spacer()

                        Image("white_drone")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .padding(.trailing, 20)
                    }

                    // Video + Point Cloud
                    HStack(spacing: 20) {
                        ZStack {
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: geometry.size.width * 0.45,
                                       height: geometry.size.height * 0.35)

                            if vm.isPlaying {
                                VideoPlayer(player: vm.player)
                                    .frame(width: geometry.size.width * 0.45,
                                           height: geometry.size.height * 0.35)
                                    .disabled(true)
                            } else {
                                Text("Drone view")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.brown.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }

                        ZStack {
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: geometry.size.width * 0.45,
                                       height: geometry.size.height * 0.35)

                            if showPointCloud && vm.isPlaying {
                                Image("point_cloud")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width * 0.45,
                                           height: geometry.size.height * 0.35)
                            } else {
                                Text("Point Cloud")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.brown.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // Data + Controls + Detection
                    HStack(spacing: 20) {
                        // Flight Data
                        VStack(spacing: 20) {
                            if vm.currentFlightIndex < vm.flightSamples.count {
                                let cd = vm.flightSamples[vm.currentFlightIndex]
                                FlightDataRow(label: "Time", value: formatTime(milliseconds: cd.timeMs))
                                FlightDataRow(label: "Datetime", value: cd.dateTimeUTC)
                                FlightDataRow(label: "Height Above Takeoff", value: String(format: "%.3f ft", cd.heightTakeoff))
                                FlightDataRow(label: "Z Speed", value: String(format: "%.3f mph", cd.zSpeed))
                                FlightDataRow(label: "Fly State", value: cd.flyState)
                            } else {
                                FlightDataRow(label: "Time", value: "00:00:00")
                                FlightDataRow(label: "UTC", value: "--:--:--")
                                FlightDataRow(label: "Height Above Takeoff", value: "0 ft")
                                FlightDataRow(label: "Z Speed", value: "0 mph")
                                FlightDataRow(label: "Fly State", value: "Unknown")
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.3)))
                        .frame(width: geometry.size.width * 0.4)

                        // Controls & Icon
                        VStack(spacing: 10) {
                            Button(action: {
                                if vm.isPlaying {
                                    vm.stop()
                                    showPointCloud = false
                                } else {
                                    vm.start()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        showPointCloud = true
                                    }
                                }
                            }) {
                                Circle()
                                    .fill(vm.isPlaying ? Color.red : Color.green)
                                    .frame(width: 50, height: 50)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .overlay(
                                        Text(vm.isPlaying ? "Stop" : "Start")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                            .bold()
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            Image(vm.isAlienDetectedNow ? "aliens" : "aliens_grayscale")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .animation(.easeInOut, value: vm.isAlienDetectedNow)
                        }

                        // Alien Detection Pane
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alien detected:")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.top, 12)
                                .padding(.leading, 12)

                            if vm.seenDetections.isEmpty {
                                Text("No aliens detected yet")
                                    .foregroundColor(.white.opacity(0.7))
                                    .italic()
                                    .frame(maxWidth: .infinity,
                                           maxHeight: .infinity,
                                           alignment: .center)
                            } else {
                                ScrollView(.vertical, showsIndicators: true) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ms    datetime          label prob%  x  y  w  h")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.8))
                                        ForEach(vm.seenDetections) { d in
                                            Text(d.description)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .frame(width: geometry.size.width * 0.4,
                               height: 170,
                               alignment: .topLeading)
                        .background(Color.brown)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }

    private func formatTime(milliseconds: Double) -> String {
        let totalSeconds = Int(milliseconds / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let ms = Int(milliseconds.truncatingRemainder(dividingBy: 1000) / 10)
        return String(format: "%02d:%02d:%02d", minutes, seconds, ms)
    }
}

// MARK: - FlightDataRow
struct FlightDataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.orange)
                .bold()
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
