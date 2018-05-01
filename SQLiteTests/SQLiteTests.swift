//
//  SQLiteTests.swift
//  SQLiteTests
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import XCTest
@testable import SQLite

class SQLiteTests: XCTestCase {
    
    private static let dbName: String = "test.db"
    private var configuration = Configuration(fileName: dbName)
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testConfiguration() {
        XCTAssertTrue(configuration.path != nil)
        XCTAssertTrue(configuration.path!.contains(SQLiteTests.dbName))
    }
    
    func testDbOpen() {
        let connection = try? Connection.open(configuration: self.configuration)
        XCTAssertTrue(connection != nil)
        XCTAssertTrue(connection!.isOpen)
    }
    
    func testExecute() throws {
        let db = Db(configuration: self.configuration)
        
        try db.execute(sql: "DROP TABLE IF EXISTS test", callback: nil)
        try db.execute(sql: "CREATE TABLE test(id INT, value TEXT)", callback: nil)
        try db.execute(sql: "INSERT INTO test(id, value) VALUES (1, 'test1')", callback: nil)
        try db.execute(sql: "INSERT INTO test(id, value) VALUES (2, 'test2')", callback: nil)
        try db.execute(sql: "INSERT INTO test(id, value) VALUES (3, 'test3')", callback: nil)
        
        var rows = [[String: String]]()
        let callback: Db.ExecuteCallbackType = {
            result in
            rows.append(result)
            return 0
        }
        
        try db.execute(sql: "SELECT id, value FROM test ORDER BY id ASC", callback: callback)
        
        XCTAssertTrue(rows.count == 3)
        XCTAssertTrue(rows[1]["value"] == "test2")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
