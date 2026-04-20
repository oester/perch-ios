import SwiftUI

struct RecordCard: View {
    let record: Detection

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: record.imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.15)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(record.commonName)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text(record.scientificName)
                    .font(.callout)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let date = record.parsedDate {
                    Text(date, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                confidenceBadge
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var confidenceBadge: some View {
        let pct   = Int(record.confidence * 100)
        let color: Color = record.confidence >= 0.8 ? .green
                         : record.confidence >= 0.5 ? .yellow : .red
        return Text("\(pct)%")
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }
}
