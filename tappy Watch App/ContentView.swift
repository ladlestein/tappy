//
//  ContentView.swift
//  tappy Watch App
//
//  Created by Larry Edelstein on 3/16/25.
//

import SwiftUI
import WatchKit
//import SensorKit
import CoreMotion

struct ContentView: View {
    @StateObject private var gestureDetector = GestureDetector()
    
    var body: some View {
        VStack {
            Text(gestureDetector.detectedGesture)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Count: \(gestureDetector.gestureCount)")
                .font(.system(size: 14))
                .padding(.bottom, 5)
            
            Button("Reset") {
                gestureDetector.resetCount()
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            gestureDetector.startMonitoring()
        }
        .onDisappear {
            gestureDetector.stopMonitoring()
        }
    }
}

class GestureDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var detectedGesture: String = "Waiting for gesture..."
    @Published var gestureCount: Int = 0
    
    // Thresholds for gesture detection
    private let accelerationThreshold: Double = 1.8
    private let tapThreshold: Double = 2.5
    private let wristTurnThreshold: Double = 1.2
    
    // Cooldown to prevent multiple detections
    private var lastDetectionTime: Date = Date.distantPast
    private let cooldownInterval: TimeInterval = 0.5
    
    func startMonitoring() {
        if motionManager.isDeviceMotionAvailable {
            // Increase update frequency for better gesture detection
            motionManager.deviceMotionUpdateInterval = 0.05
            motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (motion, error) in
                guard let self = self, let motion = motion else { return }
                
                DispatchQueue.main.async {
                    self.processMotionData(motion)
                }
            }
        } else {
            detectedGesture = "Motion sensing unavailable"
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func resetCount() {
        gestureCount = 0
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        // Only process if we're not in cooldown
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= cooldownInterval else { return }
        
        // Get motion data
        let acceleration = motion.userAcceleration
        let gravity = motion.gravity
        let rotation = motion.rotationRate
        
        // Calculate magnitude
        let accMagnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        let rotMagnitude = sqrt(pow(rotation.x, 2) + pow(rotation.y, 2) + pow(rotation.z, 2))
        
        // Detect gestures
        if accMagnitude > tapThreshold && acceleration.z > 1.8 {
            updateGesture("Tap Detected")
        } else if accMagnitude > tapThreshold && acceleration.z < -1.8 {
            updateGesture("Double Tap Detected")
        } else if rotMagnitude > wristTurnThreshold && rotation.y > 1.0 {
            // Swapped direction for correct detection
            updateGesture("Wrist Turn Left") 
        } else if rotMagnitude > wristTurnThreshold && rotation.y < -1.0 {
            // Swapped direction for correct detection
            updateGesture("Wrist Turn Right")
        } else if accMagnitude > accelerationThreshold && abs(acceleration.x) > 1.5 * abs(acceleration.y) && abs(acceleration.x) > 1.5 * abs(acceleration.z) {
            if acceleration.x > 0 {
                updateGesture("Flick Right")
            } else {
                updateGesture("Flick Left")
            }
        } else if accMagnitude > accelerationThreshold && abs(acceleration.y) > 1.5 * abs(acceleration.x) && abs(acceleration.y) > 1.5 * abs(acceleration.z) {
            if acceleration.y > 0 {
                updateGesture("Flick Up")
            } else {
                updateGesture("Flick Down")
            }
        }
    }
    
    private func updateGesture(_ gesture: String) {
        lastDetectionTime = Date()
        detectedGesture = gesture
        gestureCount += 1
    }
}

#Preview {
    ContentView()
}
