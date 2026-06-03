import SwiftUI

struct LargeFilesView: View {
    @ObservedObject var model: AppModel
    @State private var showConfirm = false

    private let options: [(label: String, mb: Int64)] =
        [("> 100 MB", 100), ("> 500 MB", 500), ("> 1 GB", 1024), ("> 5 GB", 5120)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("阈值", selection: $model.largeThresholdMB) {
                    ForEach(options, id: \.mb) { Text($0.label).tag($0.mb) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
                Button { model.scanLargeFiles() } label: { Label("扫描", systemImage: "magnifyingglass") }
                    .disabled(model.isScanningLarge)
                if model.isScanningLarge {
                    ProgressView().controlSize(.small)
                    Text("扫描主目录中…").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if model.largeFiles.isEmpty {
                Spacer()
                Text(model.isScanningLarge ? "扫描中…" : "点击「扫描」查找大文件")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(model.largeFiles) { file in
                            LargeFileRow(file: file,
                                         isOn: model.selectedLargeFiles.contains(file.id),
                                         toggle: { model.toggleLarge(file.id) },
                                         reveal: { model.revealInFinder(file.url) })
                        }
                    }
                    .padding(16)
                }
            }

            Divider()

            HStack {
                Text("\(model.largeFiles.count) 个大文件").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button { showConfirm = true } label: {
                    Text("移到废纸篓 (\(ByteCountFormatter.string(fromByteCount: model.selectedLargeBytes, countStyle: .file)))")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.selectedLargeFiles.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .confirmationDialog("移到废纸篓？", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("移到废纸篓", role: .destructive) { model.trashSelectedLargeFiles() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将选中的 \(model.selectedLargeFiles.count) 个文件移到废纸篓（可恢复）。")
        }
    }
}

struct LargeFileRow: View {
    let file: LargeFileItem
    let isOn: Bool
    let toggle: () -> Void
    let reveal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .font(.title3)
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name).font(.body).lineLimit(1).truncationMode(.middle)
                Text(file.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                .font(.callout).monospacedDigit().foregroundStyle(.secondary)
            Button { reveal() } label: { Image(systemName: "arrow.right.circle") }
                .buttonStyle(.borderless)
                .help("在 Finder 中显示")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 9).fill(Color.primary.opacity(0.05)))
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
    }
}
