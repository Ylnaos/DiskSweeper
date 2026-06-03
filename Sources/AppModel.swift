import Foundation
import SwiftUI
import AppKit

@MainActor
final class AppModel: ObservableObject {
    // Safe cleanup
    @Published var disk = DiskInfo.current()
    @Published var categories = CleanupCategory.all
    @Published var sizes: [String: Int64] = [:]
    @Published var selected: Set<String>
    @Published var isScanningCategories = false
    @Published var permanentDelete = false          // off = move to Trash, on = permanent delete

    // Large files
    @Published var largeFiles: [LargeFileItem] = []
    @Published var selectedLargeFiles: Set<UUID> = []
    @Published var isScanningLarge = false
    @Published var largeThresholdMB: Int64 = 500

    @Published var resultMessage: String?

    init() {
        selected = Set(CleanupCategory.all.filter { $0.defaultSelected }.map { $0.id })
    }

    // MARK: - Safe cleanup

    var selectedTotalBytes: Int64 { selected.reduce(0) { $0 + (sizes[$1] ?? 0) } }
    var scannedTotalBytes: Int64 { categories.reduce(0) { $0 + (sizes[$1.id] ?? 0) } }
    var allSelected: Bool { selected.count == categories.count }

    func scanCategories() {
        guard !isScanningCategories else { return }
        isScanningCategories = true
        resultMessage = nil
        let cats = categories
        Task {
            for cat in cats {
                let size = await Task.detached { ScanEngine.size(of: cat.paths) }.value
                self.sizes[cat.id] = size
            }
            self.disk = await Task.detached { DiskInfo.current() }.value
            self.isScanningCategories = false
        }
    }

    func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    func selectAll() {
        if allSelected { selected.removeAll() } else { selected = Set(categories.map { $0.id }) }
    }

    func cleanSelected() {
        let toClean = categories.filter { selected.contains($0.id) }
        guard !toClean.isEmpty else { return }
        let perm = permanentDelete
        let snapshot = sizes
        Task {
            let result = await Task.detached {
                CleanEngine.clean(categories: toClean, permanentDefault: perm, scannedSizes: snapshot)
            }.value
            self.resultMessage = Self.message(for: result)
            self.scanCategories()
        }
    }

    static func message(for r: CleanResult) -> String {
        var parts: [String] = []
        if r.anyPermanent && r.freedBytes > 0 {
            parts.append("永久删除并释放 " + fmt(r.freedBytes))
        }
        if r.anyTrashed && r.trashedBytes > 0 {
            parts.append("移动 " + fmt(r.trashedBytes) + " 到废纸篓（清空废纸篓后释放空间）")
        }
        if parts.isEmpty { parts.append("没有可清理的内容") }
        var msg = parts.joined(separator: "；")
        if r.errorCount > 0 { msg += "。\(r.errorCount) 项因被占用或权限不足而跳过" }
        return msg
    }

    // MARK: - Large files

    var selectedLargeBytes: Int64 {
        largeFiles.filter { selectedLargeFiles.contains($0.id) }.reduce(0) { $0 + $1.size }
    }

    func toggleLarge(_ id: UUID) {
        if selectedLargeFiles.contains(id) { selectedLargeFiles.remove(id) } else { selectedLargeFiles.insert(id) }
    }

    func scanLargeFiles() {
        guard !isScanningLarge else { return }
        isScanningLarge = true
        largeFiles = []
        selectedLargeFiles = []
        resultMessage = nil
        let root = NSHomeDirectory()
        let minBytes = largeThresholdMB * 1024 * 1024
        Task {
            let files = await Task.detached { ScanEngine.largeFiles(root: root, minBytes: minBytes) }.value
            self.largeFiles = files
            self.isScanningLarge = false
        }
    }

    func trashSelectedLargeFiles() {
        let urls = largeFiles.filter { selectedLargeFiles.contains($0.id) }.map { $0.url }
        guard !urls.isEmpty else { return }
        Task {
            let errors = await Task.detached { CleanEngine.moveToTrash(urls) }.value
            let moved = urls.count - errors
            self.resultMessage = "已移动 \(moved) 个文件到废纸篓（清空废纸篓后释放空间）" + (errors > 0 ? "，\(errors) 个失败" : "")
            self.scanLargeFiles()
            self.disk = DiskInfo.current()
        }
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private static func fmt(_ b: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
    }
}
