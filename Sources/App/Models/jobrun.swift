import Fluent
import Vapor

final class JobRun: Model, Content {
    static let schema = "job_runs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "job_id")
    var job: Job
    
    @Field(key: "status")
    var status: String // "pending", "running", "success", "failed"
    
    @Field(key: "output")
    var output: String?
    
    @Field(key: "attempt")
    var attempt: Int
    
    @Timestamp(key: "started_at", on: .none)
    var startedAt: Date?
    
    @Timestamp(key: "finished_at", on: .none)
    var finishedAt: Date?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
}