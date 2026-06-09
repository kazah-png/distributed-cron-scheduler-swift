import Vapor
import Fluent

struct JobController {
    let app: Application
    
    func list(req: Request) async throws -> [Job] {
        try await Job.query(on: app.db).all()
    }
    
    func create(req: Request) async throws -> Job {
        let input = try req.content.decode(CreateJobInput.self)
        let job = Job(cron: input.cron, command: input.command, retries: input.retries)
        try await job.save(on: app.db)
        return job
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let jobId = req.parameters.get("jobId", as: UUID.self) else { throw Abort(.badRequest) }
        guard let job = try await Job.find(jobId, on: app.db) else { throw Abort(.notFound) }
        try await job.delete(on: app.db)
        return .noContent
    }
    
    func runs(req: Request) async throws -> [JobRun] {
        guard let jobId = req.parameters.get("jobId", as: UUID.self) else { throw Abort(.badRequest) }
        let job = try await Job.find(jobId, on: app.db)
        guard let job else { throw Abort(.notFound) }
        return try await job.$runs.get(on: app.db).sorted(by: { $0.createdAt ?? Date() > $1.createdAt ?? Date() })
    }
}

struct CreateJobInput: Content {
    let cron: String
    let command: String
    let retries: Int
}