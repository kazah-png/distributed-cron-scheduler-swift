import Vapor
import Fluent

actor CronScheduler {
    private let app: Application
    private var timerTask: Task<Void, Never>?
    private let executor: JobExecutor
    
    init(app: Application) {
        self.app = app
        self.executor = JobExecutor(app: app)
    }
    
    func start() async {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                let now = Date()
                // Cada minuto revisar tareas
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                await self?.checkJobs(at: now)
            }
        }
    }
    
    private func checkJobs(at date: Date) async {
        guard let leaderElector = app.leaderElector as? LeaderElector,
              await leaderElector.isCurrentlyLeader() else { return }
        
        let jobs = try? await Job.query(on: app.db)
            .filter(\.$enabled == true)
            .all()
        
        for job in jobs ?? [] {
            if CronParser.matches(cron: job.cron, date: date) {
                app.logger.info("Executing job \(job.id?.uuidString ?? "") at \(date)")
                Task {
                    try? await executor.execute(job: job)
                }
            }
        }
    }
    
    func stop() {
        timerTask?.cancel()
    }
}