import Vapor
import Fluent

struct JobExecutor {
    let app: Application
    
    func execute(job: Job, attempt: Int = 0) async throws {
        let run = JobRun()
        run.$job.id = try job.requireID()
        run.status = "running"
        run.attempt = attempt
        run.startedAt = Date()
        try await run.save(on: app.db)
        
        // Simular ejecución del comando (en realidad podrías usar Process)
        let output = await shell(job.command)
        
        run.status = output.success ? "success" : "failed"
        run.output = output.message
        run.finishedAt = Date()
        try await run.save(on: app.db)
        
        if !output.success, attempt < job.retries {
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
            try await execute(job: job, attempt: attempt + 1)
        }
    }
    
    private func shell(_ command: String) async -> (success: Bool, message: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (process.terminationStatus == 0, output)
        } catch {
            return (false, error.localizedDescription)
        }
    }
}