import Fluent

struct CreateJob: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("jobs")
            .id()
            .field("cron", .string, .required)
            .field("command", .string, .required)
            .field("retries", .int, .required)
            .field("enabled", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("jobs").delete()
    }
}