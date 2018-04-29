//
//  SQLiteQueuedProtocol.swift
//  SQLite
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import Foundation

protocol QueuedProtocol {
    func enqueue(block: @escaping (_ db: Db) -> Void) -> Void
    func enqueueWithTransaction(block: @escaping (_ db: Db, _ shouldRollBack: inout Bool) -> Void) -> Void
}

