import SwiftUI

struct SpeciesRow: View {
    let species: Species

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: species.imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.15)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(species.commonName)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text(species.scientificName)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(species.count, format: .number)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
