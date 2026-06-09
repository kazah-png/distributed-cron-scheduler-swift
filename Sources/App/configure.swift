import Vapor
import Fluent
import FluentPostgresDriver

public func configure(_ app: Application) async throws {
    // Configurar base de datos
    guard let dbUrl = Environment.get("DATABASE_URL") else {
        fatalError("DATABASE_URL not set")
    }
    try app.databases.use(.postgres(url: dbUrl), as: .psql)
    
    // Migraciones
    app.migrations.add(CreateJob())
    app.migrations.add(CreateJobRun())
    try await app.autoMigrate()
    
    // Registro de servicios
    app.logger.info("Node ID: \(Environment.get("NODE_ID") ?? "unknown")")
    let leaderElector = try LeaderElector(app: app)
    app.leaderElector = leaderElector
    let cronScheduler = CronScheduler(app: app)
    app.cronScheduler = cronScheduler
    
    // Iniciar elección de líder en background
    Task {
        await leaderElector.start()
        await cronScheduler.start()
    }
    
    // Controladores
    let jobController = JobController(app: app)
    app.get("jobs", use: jobController.list)
    app.post("jobs", use: jobController.create)
    app.delete("jobs", ":jobId", use: jobController.delete)
    app.get("jobs", ":jobId", "runs", use: jobController.runs)
}

extension Application {
    var leaderElector: LeaderElector {
        get { self.storage[LeaderElectorKey.self]! }
        set { self.storage[LeaderElectorKey.self] = newValue }
    }
    var cronScheduler: CronScheduler {
        get { self.storage[CronSchedulerKey.self]! }
        set { self.storage[CronSchedulerKey.self] = newValue }
    }
}

private struct LeaderElectorKey: StorageKey {
    typealias Value = LeaderElector
}
private struct CronSchedulerKey: StorageKey {
    typealias Value = CronScheduler
}