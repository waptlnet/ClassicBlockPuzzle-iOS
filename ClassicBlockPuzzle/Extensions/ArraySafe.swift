import Foundation

// MARK: - Array subscript (safe:)

extension Array {
    /// 安全下标访问：超出范围返回 nil
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
