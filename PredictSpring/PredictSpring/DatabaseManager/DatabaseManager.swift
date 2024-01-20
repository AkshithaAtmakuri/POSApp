//
//  DatabaseManager.swift
//  PredictSpring
//
//  Created by Akshitha atmakuri on 19/01/24.
//

import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var database: Connection!
    
    private let products = Table("products")
    private let productId = Expression<String>("productId")
    private let title = Expression<String>("title")
    private let listPrice = Expression<Double>("listPrice")
    private let salesPrice = Expression<Double>("salesPrice")
    private let color = Expression<String>("color")
    private let size = Expression<String>("size")
    
    internal init() {
        do {
            database = try Connection(.inMemory)
            try database.execute("PRAGMA foreign_keys = ON")
            createTable()
        } catch {
            // Handle database initialization error
            print("Error initializing database: \(error)")
        }
    }
    
    func createTable() {
        do {
            try database.run(products.drop(ifExists: true))
            try database.run(products.create { table in
                table.column(productId, primaryKey: true)
                table.column(title)
                table.column(listPrice)
                table.column(salesPrice)
                table.column(color)
                table.column(size)
            })
            
            try database.run("CREATE INDEX IF NOT EXISTS index_productId ON products(productId)")
        } catch {
            print("Error creating table or index: \(error)")
        }
    }
    
    func insertProducts(products: [Product]) {
        do {
            try database.transaction {
                for product in products {
                    try self.database.run(self.products.insert(
                        self.productId <- product.productId,
                        self.title <- product.title,
                        self.listPrice <- product.listPrice,
                        self.salesPrice <- product.salesPrice,
                        self.color <- product.color,
                        self.size <- product.size
                    ))
                }
            }
        } catch {
            print("Error inserting products: \(error)")
        }
    }
    
    func indexProductIdColumn() {
        do {
            try database.run(products.createIndex(productId, ifNotExists: true))
        } catch {
            print("Error creating index: \(error)")
        }
    }
    
    func getProducts(searchText: String, page: Int, pageSize: Int) -> [Product] {
        var products: [Product] = []
        do {
            let offset = (page - 1) * pageSize
            let query = """
                    SELECT * FROM products
                    WHERE LOWER(productId) LIKE ? OR LOWER(title) LIKE ?
                    LIMIT ? OFFSET ?
                """
            let filteredProducts = try database?.prepare(query, "%\(searchText.lowercased())%", "%\(searchText.lowercased())%", pageSize, offset)
            
            for row in filteredProducts! {
                let product = Product(
                    productId: row[0] as! String,
                    title: row[1] as! String,
                    listPrice: row[2] as! Double,
                    salesPrice: row[3] as! Double,
                    color: row[4] as! String,
                    size: row[5] as! String
                )
                products.append(product)
            }
        } catch {
            print("Unable to get products")
        }
        return products
    }
}
