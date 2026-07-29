import Foundation // for Bundle
import os

enum Log {
    // MARK: - Constants

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: ""
    )

    // MARK: - Methods

    private static func buildMessage(
        _ type: OSLogType,
        _ message: String,
        _ file: String,
        _ function: String,
        _ line: Int
    ) -> String {
        let fileName = file.components(separatedBy: "/").last ?? "unknown"
        let emoji = emoji(for: type)
        let name = name(for: type)
        return """
        \(fileName) \(function) line \(line)
        \(emoji) \(name): \(message)
        """
    }

    private static func emoji(for type: OSLogType) -> String {
        switch type {
        case .debug:
            "🪲"
        case .error:
            "❌"
        case .fault:
            "☠️"
        case .info:
            "🔎"
        default:
            ""
        }
    }

    private static func name(for type: OSLogType) -> String {
        switch type {
        case .debug:
            "debug"
        case .error:
            "error"
        case .fault:
            "fault"
        case .info:
            "info"
        default:
            ""
        }
    }

    static func debug(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.debug, message, file, function, line)
        log(message: message, type: .debug)
    }

    static func error(
        _ err: Error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let message = err.localizedDescription
        error(message, file: file, function: function, line: line)
    }

    static func error(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.error, message, file, function, line)
        log(message: message, type: .error)
    }

    static func fault(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.fault, message, file, function, line)
        log(message: message, type: .fault)
    }

    static func info(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.info, message, file, function, line)
        log(message: message, type: .info)
    }

    /*
     This sets "privacy" to "public" to prevent values
     in string interpolations from being redacted.
     From https://developer.apple.com/documentation/os/logger
     "When you include an interpolated string or custom object in your message,
     the system redacts the value of that string or object by default.
     This behavior prevents the system from leaking potentially user-sensitive
     information in the log files, such as the user’s account information.
     If the data doesn’t contain sensitive information, change the
     privacy option of that value when logging the information."
     */
    private static func log(message: String, type: OSLogType) {
        switch type {
        case .debug:
            // The argument in each of the logger calls below
            // MUST be a string interpolation!
            logger.debug("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        default:
            logger.log("\(message, privacy: .public)")
        }
    }
}

// This simplifies print statements that use string interpolation
// to print values with types like Bool.
// For example: print("isHavingFun = \(sd(isHavingFun))")
func sd(_ css: CustomStringConvertible) -> String {
    String(describing: css)
}
