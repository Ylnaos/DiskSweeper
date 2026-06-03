import Foundation

struct CleanResult: Sendable {
    var freedBytes: Int64 = 0
    var trashedBytes: Int64 = 0
    var errorCount: Int = 0
    var anyPermanent = false
    var anyTrashed = false
}

enum CleanEngine {
    /// Defensive guard: only ever operate on paths strictly *inside* the user's home directory.
    /// Symlinks are resolved on BOTH sides so the guarantee is intentional, not incidental — a
    /// category path that is itself a symlink pointing outside $HOME is rejected here.
    static func isSafe(_ path: String) -> Bool {
        let home = URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath().path
        let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
        guard resolved.hasPrefix(home + "/"), resolved != home else { return false }
        return true
    }

    /// Deletes the *contents* of each category path (the folders themselves are kept).
    /// Accounting uses the pre-scanned sizes; skipped items are reported via errorCount.
    static func clean(categories: [CleanupCategory], permanentDefault: Bool,
                      scannedSizes: [String: Int64]) -> CleanResult {
        var result = CleanResult()
        let fm = FileManager.default
        for category in categories {
            let permanent = permanentDefault || category.alwaysPermanent
            for path in category.paths {
                guard isSafe(path) else { continue }
                guard let children = try? fm.contentsOfDirectory(
                    at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil) else { continue }
                for child in children {
                    do {
                        if permanent {
                            try fm.removeItem(at: child)
                        } else {
                            try fm.trashItem(at: child, resultingItemURL: nil)
                        }
                    } catch {
                        result.errorCount += 1
                    }
                }
            }
            let size = scannedSizes[category.id] ?? 0
            if permanent {
                result.freedBytes += size
                result.anyPermanent = true
            } else {
                result.trashedBytes += size
                result.anyTrashed = true
            }
        }
        return result
    }

    /// Moves arbitrary files to the Trash. Returns the number of failures.
    static func moveToTrash(_ urls: [URL]) -> Int {
        let fm = FileManager.default
        var errors = 0
        for url in urls {
            do { try fm.trashItem(at: url, resultingItemURL: nil) } catch { errors += 1 }
        }
        return errors
    }
}
