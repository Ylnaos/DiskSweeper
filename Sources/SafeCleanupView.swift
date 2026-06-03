import SwiftUI

struct SafeCleanupView: View {
    @ObservedObject var model: AppModel
    @State private var showConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { model.scanCategories() } label: { Label("扫描", systemImage: "magnifyingglass") }
                    .disabled(model.isScanningCategories)
                if model.isScanningCategories { ProgressView().controlSize(.small) }
                Spacer()
                HStack(spacing: 4) {
                    Text("可清理合计").foregroundStyle(.secondary)
                    Text(fmt(model.scannedTotalBytes)).bold().monospacedDigit()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(model.categories) { cat in
                        CategoryRow(category: cat,
                                    size: model.sizes[cat.id],
                                    isOn: model.selected.contains(cat.id),
                                    scanning: model.isScanningCategories) {
                            model.toggle(cat.id)
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            HStack(spacing: 12) {
                Button(model.allSelected ? "全不选" : "全选") { model.selectAll() }
                Toggle(isOn: $model.permanentDelete) {
                    Text(model.permanentDelete ? "永久删除" : "移到废纸篓")
                }
                .toggleStyle(.switch)
                .help("关：移到废纸篓（可恢复）　开：永久删除（不可恢复）")
                Spacer()
                Button { showConfirm = true } label: {
                    Text("清理选中 (\(fmt(model.selectedTotalBytes)))")
                }
                .buttonStyle(.borderedProminent)
                .tint(model.permanentDelete ? .red : .accentColor)
                .disabled(model.selected.isEmpty || model.selectedTotalBytes == 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .confirmationDialog(model.permanentDelete ? "确认永久删除？" : "确认移到废纸篓？",
                            isPresented: $showConfirm, titleVisibility: .visible) {
            Button(model.permanentDelete ? "永久删除" : "移到废纸篓", role: .destructive) { model.cleanSelected() }
            Button("取消", role: .cancel) {}
        } message: {
            Text(confirmMessage)
        }
    }

    private func fmt(_ b: Int64) -> String { ByteCountFormatter.string(fromByteCount: b, countStyle: .file) }

    private var confirmMessage: String {
        let names = model.categories.filter { model.selected.contains($0.id) }.map { $0.name }.joined(separator: "、")
        let mode = model.permanentDelete ? "永久删除（不可恢复）" : "移到废纸篓（可恢复）"
        return "将\(mode)以下类别的内容：\n\(names)\n合计约 \(fmt(model.selectedTotalBytes))"
    }
}

struct CategoryRow: View {
    let category: CleanupCategory
    let size: Int64?
    let isOn: Bool
    let scanning: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .font(.title3)
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
            Image(systemName: category.icon)
                .font(.title3)
                .frame(width: 26)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name).font(.body.weight(.medium))
                Text(category.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let size {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.callout).monospacedDigit().foregroundStyle(.secondary)
            } else if scanning {
                ProgressView().controlSize(.small)
            } else {
                Text("—").foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(isOn ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
    }
}
