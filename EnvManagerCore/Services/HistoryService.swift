import Foundation
import SQLite3

/// 历史记录错误
public enum HistoryError: Error, LocalizedError {
    case openDatabaseFailed
    case createTableFailed
    case insertFailed
    case queryFailed
    case clearFailed

    public var errorDescription: String? {
        switch self {
        case .openDatabaseFailed: return "打开数据库失败"
        case .createTableFailed: return "创建表失败"
        case .insertFailed: return "插入历史记录失败"
        case .queryFailed: return "查询历史记录失败"
        case .clearFailed: return "清除历史记录失败"
        }
    }
}

/// 历史记录服务 - 使用 SQLite 存储操作历史
public actor HistoryService {
    private let dbURL: URL
    private var db: OpaquePointer?

    /// 初始化
    public init(dbURL: URL = Constants.historyDatabaseURL) {
        self.dbURL = dbURL
        self.db = nil

        // 创建目录（直接执行）
        let directory = dbURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                print("创建历史数据库目录: \(directory.path)")
            } catch {
                print("无法创建历史数据库目录: \(error.localizedDescription)")
            }
        }
    }

    /// 初始化数据库连接（需要在 actor 方法中调用）
    private func initializeDatabase() throws {
        if db == nil {
            if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
                print("无法打开数据库: \(dbURL.path)")
                throw HistoryError.openDatabaseFailed
            }

            // 创建表
            let createTableSQL = """
            CREATE TABLE IF NOT EXISTS history (
                id TEXT PRIMARY KEY,
                action TEXT NOT NULL,
                variableKey TEXT NOT NULL,
                oldValue TEXT,
                newValue TEXT,
                timestamp REAL NOT NULL
            );
            """

            if sqlite3_exec(db, createTableSQL, nil, nil, nil) != SQLITE_OK {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("无法创建表: \(errorMsg)")
                sqlite3_close(db)
                db = nil
                throw HistoryError.createTableFailed
            }
        }
    }

    /// 添加记录
    public func addRecord(_ record: HistoryRecord) throws {
        // 确保数据库已初始化
        try initializeDatabase()

        let insertSQL = """
        INSERT INTO history (id, action, variableKey, oldValue, newValue, timestamp)
        VALUES (?, ?, ?, ?, ?, ?);
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) != SQLITE_OK {
            sqlite3_finalize(stmt)
            throw HistoryError.insertFailed
        }

        sqlite3_bind_text(stmt, 1, record.id.uuidString, -1, nil)
        sqlite3_bind_text(stmt, 2, record.action.rawValue, -1, nil)
        sqlite3_bind_text(stmt, 3, record.variableKey, -1, nil)
        sqlite3_bind_text(stmt, 4, record.oldValue ?? "", -1, nil)
        sqlite3_bind_text(stmt, 5, record.newValue ?? "", -1, nil)
        sqlite3_bind_double(stmt, 6, record.timestamp.timeIntervalSince1970)

        if sqlite3_step(stmt) != SQLITE_DONE {
            sqlite3_finalize(stmt)
            throw HistoryError.insertFailed
        }

        sqlite3_finalize(stmt)
    }

    /// 获取所有记录
    public func getRecords() throws -> [HistoryRecord] {
        try initializeDatabase()
        let selectSQL = "SELECT id, action, variableKey, oldValue, newValue, timestamp FROM history ORDER BY timestamp DESC;"

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, selectSQL, -1, &stmt, nil) != SQLITE_OK {
            sqlite3_finalize(stmt)
            throw HistoryError.queryFailed
        }

        var records: [HistoryRecord] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let idString = String(cString: sqlite3_column_text(stmt, 0))
            let actionString = String(cString: sqlite3_column_text(stmt, 1))
            let key = String(cString: sqlite3_column_text(stmt, 2))
            let oldValueStr = String(cString: sqlite3_column_text(stmt, 3))
            let newValueStr = String(cString: sqlite3_column_text(stmt, 4))
            let timestamp = sqlite3_column_double(stmt, 5)

            let record = HistoryRecord(
                id: UUID(uuidString: idString) ?? UUID(),
                action: ActionType(rawValue: actionString) ?? .create,
                variableKey: key,
                oldValue: oldValueStr.isEmpty ? nil : oldValueStr,
                newValue: newValueStr.isEmpty ? nil : newValueStr,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )

            records.append(record)
        }

        sqlite3_finalize(stmt)
        return records
    }

    /// 获取最近的记录
    public func getRecentRecords(limit: Int = 10) throws -> [HistoryRecord] {
        try initializeDatabase()
        let selectSQL = "SELECT id, action, variableKey, oldValue, newValue, timestamp FROM history ORDER BY timestamp DESC LIMIT \(limit);"

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, selectSQL, -1, &stmt, nil) != SQLITE_OK {
            sqlite3_finalize(stmt)
            throw HistoryError.queryFailed
        }

        var records: [HistoryRecord] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let idString = String(cString: sqlite3_column_text(stmt, 0))
            let actionString = String(cString: sqlite3_column_text(stmt, 1))
            let key = String(cString: sqlite3_column_text(stmt, 2))
            let oldValueStr = String(cString: sqlite3_column_text(stmt, 3))
            let newValueStr = String(cString: sqlite3_column_text(stmt, 4))
            let timestamp = sqlite3_column_double(stmt, 5)

            let record = HistoryRecord(
                id: UUID(uuidString: idString) ?? UUID(),
                action: ActionType(rawValue: actionString) ?? .create,
                variableKey: key,
                oldValue: oldValueStr.isEmpty ? nil : oldValueStr,
                newValue: newValueStr.isEmpty ? nil : newValueStr,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )

            records.append(record)
        }

        sqlite3_finalize(stmt)
        return records
    }

    /// 清除历史
    public func clearHistory() throws {
        try initializeDatabase()
        let deleteSQL = "DELETE FROM history;"

        if sqlite3_exec(db, deleteSQL, nil, nil, nil) != SQLITE_OK {
            throw HistoryError.clearFailed
        }
    }

    /// 关闭数据库
    deinit {
        sqlite3_close(db)
    }
}