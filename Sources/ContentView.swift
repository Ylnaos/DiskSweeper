import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var tab: Tab = .clean

    enum Tab: Hashable { case clean, large }

    var body: some View {
        VStack(spacing: 0) {
            DiskHeaderView(disk: model.disk)

            Picker("", selection: $tab) {
                Text("安全清理").tag(Tab.clean)
                Text("大文件").tag(Tab.large)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            Group {
                switch tab {
                case .clean: SafeCleanupView(model: model)
                case .large: LargeFilesView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let msg = model.resultMessage {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    Text(msg).font(.callout).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .frame(minWidth: 640, minHeight: 520)
    }
}

struct DiskHeaderView: View {
    let disk: DiskInfo

    var body: some View {
        HStack(spacing: 16) {
            DiskRing(fraction: disk.usedFraction).frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text("磁盘清道夫").font(.title2.bold())
                Text("共 \(fmt(disk.total)) · 已用 \(fmt(disk.used)) · 可用 \(fmt(disk.free))")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.regularMaterial)
    }

    private func fmt(_ b: Int64) -> String { ByteCountFormatter.string(fromByteCount: b, countStyle: .file) }
}

struct DiskRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 7)
            Circle()
                .trim(from: 0, to: max(0.01, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((fraction * 100).rounded()))%").font(.caption2.bold()).monospacedDigit()
        }
    }

    private var color: Color {
        switch fraction {
        case ..<0.7: return .green
        case ..<0.9: return .orange
        default: return .red
        }
    }
}
