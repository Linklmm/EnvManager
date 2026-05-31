import Foundation
import CryptoKit

/// 加密错误
enum CryptoError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed
    case passwordStorageFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "字符串编码失败"
        case .decodingFailed:
            return "数据解码失败"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        case .passwordStorageFailed:
            return "密码存储失败"
        }
    }
}

/// 加密服务 - 使用 AES 加密敏感信息
actor CryptoService {
    private var key: SymmetricKey

    /// 初始化加密服务
    init() {
        self.key = Self.getOrCreateKey()
    }

    /// 从 Keychain 获取或创建密钥
    private static func getOrCreateKey() -> SymmetricKey {
        let keyName = "EnvManagerCryptoKey"

        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keyName,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        if status == errSecSuccess, let data = result as? Data {
            return SymmetricKey(data: data)
        }

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }

        let addQuery = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keyName,
            kSecValueData: keyData,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ] as CFDictionary

        SecItemAdd(addQuery, nil)

        return newKey
    }

    /// 加密字符串
    func encrypt(_ plaintext: String) throws -> String {
        guard let data = plaintext.data(using: .utf8) else {
            throw CryptoError.encodingFailed
        }

        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }

        return combined.base64EncodedString()
    }

    /// 解密字符串
    func decrypt(_ ciphertext: String) throws -> String {
        guard let data = Data(base64Encoded: ciphertext) else {
            throw CryptoError.decodingFailed
        }

        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decodingFailed
        }

        return plaintext
    }

    /// 检查是否已设置密码
    func isPasswordSet() -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "EnvManagerPassword",
            kSecReturnData: false
        ] as CFDictionary

        let status = SecItemCopyMatching(query, nil)
        return status == errSecSuccess
    }

    /// 设置密码
    func setPassword(_ password: String) throws {
        let serviceName = "EnvManagerPassword"

        let deleteQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName
        ] as CFDictionary
        SecItemDelete(deleteQuery)

        guard let data = password.data(using: .utf8) else {
            throw CryptoError.encodingFailed
        }

        let addQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ] as CFDictionary

        let status = SecItemAdd(addQuery, nil)
        if status != errSecSuccess {
            throw CryptoError.passwordStorageFailed
        }
    }

    /// 验证密码
    func verifyPassword(_ password: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "EnvManagerPassword",
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        if status == errSecSuccess, let data = result as? Data {
            let storedPassword = String(data: data, encoding: .utf8)
            return storedPassword == password
        }

        return false
    }
}