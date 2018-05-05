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
    private weak var db: Db?
    private weak var statement: Statement?
    
    init(statement: Statement, db: Db) {
        self.db = db
        self.statement = statement
    }
    
    public func once() -> Bool {
        let rc: Int32 = sqlite3_step(statement!.ptr)
        return rc == SQLITE_OK || rc == SQLITE_DONE
    }
    
    public func next() -> Bool {
        return true
    }
    
    public func close() {
        self.statement?.reset()
        self.db?.resultSetClosed(resultSet: self)
        
        self.db = nil
        self.statement = nil
    }
    
    deinit {
        self.close()
    }
    
    /*
     
     sqlite3_stmt *stmt;
     const char *sql = "SELECT ID, Name FROM User";
     int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
     if (rc != SQLITE_OK) {
     print("error: ", sqlite3_errmsg(db));
     return;
     }
     while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
     int id           = sqlite3_column_int (stmt, 0);
     const char *name = sqlite3_column_text(stmt, 1);
     // ...
     }
     if (rc != SQLITE_DONE) {
     print("error: ", sqlite3_errmsg(db));
     }
     sqlite3_finalize(stmt);
     
     */
}

