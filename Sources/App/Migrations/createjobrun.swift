import Fluent

struct CreateJobRun: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("job_runs")
            .id()
            .field("job_id", .uuid, .required, .references("jobs", "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("output", .string)
            .field("attempt", .int, .required)
            .field("started_at", .datetime)
            .field("finished_at", .datetime)
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("job_runs").delete()
    }
}