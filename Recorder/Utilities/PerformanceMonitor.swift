//
//  PerformanceMonitor.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import OSLog

final class PerformanceMonitor {

    static let shared = PerformanceMonitor()

    private let logger = Logger(subsystem: "com.app.recorder", category: "performance")
    private var measurements: [String: CFAbsoluteTime] = [:]
    private let queue = DispatchQueue(label: "com.app.recorder.performance", qos: .utility)

    private init() {}

    func startMeasuring(_ operation: String) {
        queue.async { [weak self] in
            self?.measurements[operation] = CFAbsoluteTimeGetCurrent()
        }
    }

    @discardableResult
    func endMeasuring(_ operation: String, threshold: TimeInterval? = nil) -> TimeInterval {
        var elapsed: TimeInterval = 0

        queue.sync { [weak self] in
            guard let self = self,
                  let startTime = self.measurements[operation] else { return }

            elapsed = CFAbsoluteTimeGetCurrent() - startTime
            self.measurements.removeValue(forKey: operation)

            let formattedTime = String(format: "%.3f", elapsed)

            if let threshold = threshold, elapsed > threshold {
                self.logger.warning("\(operation) took \(formattedTime)s (threshold: \(String(format: "%.3f", threshold))s)")
            } else {
                self.logger.info("\(operation) completed in \(formattedTime)s")
            }
        }

        return elapsed
    }

    func measure<T>(_ operation: String, threshold: TimeInterval? = nil, _ closure: () throws -> T) rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation, threshold: threshold) }
        return try closure()
    }

    func measureAsync<T>(_ operation: String, threshold: TimeInterval? = nil, _ closure: () async throws -> T) async rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation, threshold: threshold) }
        return try await closure()
    }

    func logMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
            logger.info("Memory usage: \(String(format: "%.2f", usedMemoryMB)) MB")
        }
    }

    func logFPS(_ fps: Double) {
        if fps < 30 {
            logger.warning("Low FPS: \(String(format: "%.1f", fps))")
        }
    }

    func clearMeasurements() {
        queue.async { [weak self] in
            self?.measurements.removeAll()
        }
    }
}

extension PerformanceMonitor {

    enum Operation {
        static let notesListLoad = "Notes List Load"
        static let noteSearch = "Note Search"
        static let noteCreate = "Note Create"
        static let noteUpdate = "Note Update"
        static let noteDelete = "Note Delete"
        static let audioRecordStart = "Audio Record Start"
        static let audioRecordStop = "Audio Record Stop"
        static let transcriptionStart = "Transcription Start"
        static let transcriptionComplete = "Transcription Complete"
        static let modelLoad = "Whisper Model Load"
        static let audioImport = "Audio Import"
        static let fileOperation = "File Operation"
    }

    enum Threshold {
        static let notesListLoad: TimeInterval = 0.5
        static let noteSearch: TimeInterval = 0.1
        static let noteOperation: TimeInterval = 0.2
        static let audioOperation: TimeInterval = 0.5
        static let transcription: TimeInterval = 60.0
        static let modelLoad: TimeInterval = 5.0
        static let fileOperation: TimeInterval = 0.1
    }
}
