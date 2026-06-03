import Foundation

/// A curated, safe-to-clean category. Only the *contents* of these folders are ever removed.
struct CleanupCategory: Identifiable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String            // SF Symbol
    let paths: [String]         // absolute, tilde-expanded
    let alwaysPermanent: Bool   // true for Trash (you can't move the Trash to the Trash)
    let defaultSelected: Bool

    static let all: [CleanupCategory] = {
        func e(_ p: String) -> String { (p as NSString).expandingTildeInPath }
        return [
            CleanupCategory(id: "user-caches", name: "用户缓存", subtitle: "~/Library/Caches",
                            icon: "shippingbox", paths: [e("~/Library/Caches")],
                            alwaysPermanent: false, defaultSelected: true),
            CleanupCategory(id: "xcode-derived", name: "Xcode 派生数据", subtitle: "DerivedData · 编译中间产物",
                            icon: "hammer", paths: [e("~/Library/Developer/Xcode/DerivedData")],
                            alwaysPermanent: false, defaultSelected: true),
            CleanupCategory(id: "user-logs", name: "用户日志", subtitle: "~/Library/Logs",
                            icon: "doc.text", paths: [e("~/Library/Logs")],
                            alwaysPermanent: false, defaultSelected: true),
            CleanupCategory(id: "trash", name: "清空废纸篓", subtitle: "~/.Trash",
                            icon: "trash", paths: [e("~/.Trash")],
                            alwaysPermanent: true, defaultSelected: true),
            CleanupCategory(id: "ios-devicesupport", name: "iOS DeviceSupport",
                            subtitle: "调试符号 · 重连设备会重新下载", icon: "iphone",
                            paths: [e("~/Library/Developer/Xcode/iOS DeviceSupport")],
                            alwaysPermanent: false, defaultSelected: false),
            CleanupCategory(id: "npm", name: "npm 缓存", subtitle: "~/.npm/_cacache",
                            icon: "shippingbox.fill", paths: [e("~/.npm/_cacache")],
                            alwaysPermanent: false, defaultSelected: false),
            CleanupCategory(id: "gradle", name: "Gradle 缓存", subtitle: "~/.gradle/caches",
                            icon: "shippingbox.fill", paths: [e("~/.gradle/caches")],
                            alwaysPermanent: false, defaultSelected: false),
        ]
    }()
}

struct LargeFileItem: Identifiable, Sendable {
    let id = UUID()
    let url: URL
    let size: Int64
    var path: String { url.path }
    var name: String { url.lastPathComponent }
}

struct DiskInfo: Sendable {
    var total: Int64
    var free: Int64
    var used: Int64 { max(0, total - free) }
    var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }

    static func current() -> DiskInfo {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        if let v = try? url.resourceValues(forKeys: keys), let total = v.volumeTotalCapacity {
            let free = v.volumeAvailableCapacityForImportantUsage ?? 0
            return DiskInfo(total: Int64(total), free: Int64(free))
        }
        return DiskInfo(total: 0, free: 0)
    }
}
