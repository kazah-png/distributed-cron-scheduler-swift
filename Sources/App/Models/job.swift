import Fluent
import Vapor

final class Job: Model, Content {
    static let schema = "jobs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "cron")
    var cron: String
    
    @Field(key: "command")
    var command: String
    
    @Field(key: "retries")
    var retries: Int
    
    @Field(key: "enabled")
    var enabled: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$job)
    var runs: [JobRun]
    
    init() { }
    
    init(id: UUID? = nil, cron: String, command: String, retries: Int = 0, enabled: Bool = true) {
        self.id = id
        self.cron = cron
        self.command = command
        self.retries = retries
        self.enabled = enabled
    }
}