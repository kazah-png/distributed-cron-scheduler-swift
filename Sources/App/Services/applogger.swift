import Logging

struct AppLogger {
    static let label = "cron-scheduler"
    static var logger: Logger {
        var logger = Logger(label: label)
        logger.logLevel = .info
        return logger
    }
}