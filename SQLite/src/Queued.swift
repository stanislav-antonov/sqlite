import Foundation

class Queued: Db, QueuedProtocol {
    private var queue: DispatchQueue!
    private let queueNameFormat: String = "sqlite.%@"
    
    private static let dispatchSpecificKey = DispatchSpecificKey<Queued>()
    
    override init(configuration: Configuration) {
        super.init(configuration: configuration)
        
        /* Create unique queue for any object.
         Since SQLite for iOS is hopefully being compiled in multi-thread mode,
         we don't care about having the only one queue per one database.
         
         The only one restriction we're going to follow according SQLite docmentation:
         
         "Multi-thread. In this mode, SQLite can be safely used by multiple threads
         provided that no single database connection is used simultaneously in two or more threads."
         */
        
        let queueId = String(ObjectIdentifier(self).hashValue)
        let queueName = String.localizedStringWithFormat(queueNameFormat, queueId)
        
        // Create a serial queue
        self.queue = DispatchQueue(label: queueName)
        self.queue.setSpecific(key: Queued.dispatchSpecificKey, value: self)
    }
    
    private func assertReentrantEnqueue() {
        let _self = self.queue.getSpecific(key: Queued.dispatchSpecificKey)
        assert(_self !== self, "reentrant enqueue detected on the same queue that would cause a deadlock")
    }
    
    public func enqueue(block: @escaping (_ db: Db) -> Void) -> Void {
        assertReentrantEnqueue()
        
        self.queue.async {
            let _db = self as Db
            block(_db)
        }
    }
    
    public func enqueueWithTransaction(block: @escaping (_ db: Db, _ shouldRollBack: inout Bool) -> Void) -> Void {
        assertReentrantEnqueue()
        
        self.queue.async {
            var shouldRollBack: Bool = false
            
            let _db = self as Db
            _db.beginTransaction()
            block(_db, &shouldRollBack)
            
            if (shouldRollBack) {
                _db.rollback()
            } else {
                _db.commit()
            }
        }
    }
}

