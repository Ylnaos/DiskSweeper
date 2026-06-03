import Foundation

enum ScanEngine {
    /// Total size in bytes of the given paths (sum of `du -sk`). Missing paths count as 0.
    /// `du` output is only ever used as a display/estimate value — it never drives deletion,
    /// so the subprocess is kept here for speed.
    static func size(of paths: [String]) -> Int64 {
        var total: Int64 = 0
        for path in paths {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let out = Shell.run("/usr/bin/du", ["-sk", path])
            // du output is "<kb>\t<path>"; take the leading tab-delimited field.
            guard let line = out.split(separator: "\n").first,
                  let firstField = line.split(separator: "\t", maxSplits: 1).first else { continue }
            let kbString = String(firstField).trimmingCharacters(in: .whitespaces)
            guard let kb = Int64(kbString) else { continue }
            total += kb * 1024
        }
        return total
    }

    /// Files larger than `minBytes` under `root` (recursive), up to `limit` largest (descending).
    /// Uses FileManager enumeration (not a `find`/`stat` subprocess) so paths are handled
    /// natively — no output parsing, immune to filenames containing tabs/newlines.
    static func largeFiles(root: String, minBytes: Int64, limit: Int = 200) -> [LargeFileItem] {
        let fm = FileManager.default
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .totalFileAllocatedSizeKey]
        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: root),
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants],   // don't dive into .app/.bundle packages
            errorHandler: { _, _ in true }         // skip unreadable dirs, keep going
        ) else { return [] }

        var items: [LargeFileItem] = []
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: keys),
                  values.isRegularFile == true else { continue }
            let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            if size >= minBytes {
                items.append(LargeFileItem(url: url, size: size))
            }
        }
        items.sort { $0.size > $1.size }
        return items.count > limit ? Array(items.prefix(limit)) : items
    }
}
