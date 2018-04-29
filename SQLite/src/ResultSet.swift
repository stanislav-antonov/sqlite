//
//  SQLiteResultset.swift
//  SQLite
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import Foundation
import SQLite3

class ResultSet {
    private let statement: Statement!
    
    init(statement: Statement) {
        self.statement = statement
    }
    
    public func once() -> Bool {
        let rc: Int32 = sqlite3_step(statement.ptr)
        return rc == SQLITE_OK || rc == SQLITE_DONE
    }
}

