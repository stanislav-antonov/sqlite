import Foundation

protocol QueuedProtocol {
    func enqueue(block: @escaping (_ db: Db) -> Void) -> Void
    func enqueueWithTransaction(block: @escaping (_ db: Db, _ shouldRollBack: inout Bool) -> Void) -> Void
}

