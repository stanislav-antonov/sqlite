//
//  SQLiteSchemaActionsProtocol.swift
//  SQLite
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import Foundation

protocol SchemaActionsProtocol {
    var version: Int { get }
    
    func onCreate(newVersion: Int, oldVersion: Int) -> Void
    func onUpdate(newVersion: Int, oldVersion: Int) -> Void
}

