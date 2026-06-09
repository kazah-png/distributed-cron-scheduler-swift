import Vapor
import Fluent

actor LeaderElector {
    private let app: Application
    private var isLeader = false
    private var renewalTask: Task<Void, Never>?
    private let nodeId: String
    private let leaseDuration: TimeInterval = 10 // segundos
    private let renewalInterval: TimeInterval = 5
    
    init(app: Application) throws {
        self.app = app
        self.nodeId = Environment.get("NODE_ID") ?? UUID().uuidString
        try self.ensureLeaderLockTable()
    }
    
    private func ensureLeaderLockTable() throws {
        // Se puede hacer una migración aparte, pero por simplicidad usamos raw SQL
        // En producción usar una migración real.
    }
    
    func start() async {
        app.logger.info("Leader elector started on node \(nodeId)")
        await tryAcquireLeadership()
        renewalTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(renewalInterval * 1_000_000_000))
                await self?.renewLeadership()
            }
        }
    }
    
    private func tryAcquireLeadership() async {
        do {
            let db = app.db as! SQLDatabase
            // Intento de insertar o actualizar con condición de expiración
            let now = Date()
            let expiredAt = now.addingTimeInterval(-leaseDuration)
            let result = try await db.raw("""
                INSERT INTO leader_lock (id, node_id, expires_at)
                VALUES ('single', \(bind: nodeId), \(bind: now.addingTimeInterval(leaseDuration)))
                ON CONFLICT (id) DO UPDATE
                SET node_id = EXCLUDED.node_id, expires_at = EXCLUDED.expires_at
                WHERE leader_lock.expires_at < \(bind: expiredAt)
                RETURNING node_id
            """).first()
            if let row = result, let leader = try? row.decode(column: "node_id", as: String.self), leader == nodeId {
                isLeader = true
                app.logger.info("Node \(nodeId) became leader")
            } else {
                isLeader = false
            }
        } catch {
            app.logger.error("Leader election failed: \(error)")
        }
    }
    
    private func renewLeadership() async {
        guard isLeader else {
            await tryAcquireLeadership()
            return
        }
        do {
            let db = app.db as! SQLDatabase
            let now = Date()
            let newExpiry = now.addingTimeInterval(leaseDuration)
            let result = try await db.raw("""
                UPDATE leader_lock
                SET expires_at = \(bind: newExpiry)
                WHERE id = 'single' AND node_id = \(bind: nodeId) AND expires_at > \(bind: now)
                RETURNING node_id
            """).first()
            if result == nil {
                // Perdimos liderazgo
                isLeader = false
                app.logger.warning("Node \(nodeId) lost leadership")
                await tryAcquireLeadership()
            }
        } catch {
            app.logger.error("Leader renewal failed: \(error)")
        }
    }
    
    func isCurrentlyLeader() -> Bool {
        return isLeader
    }
    
    func stop() {
        renewalTask?.cancel()
        renewalTask = nil
    }
}