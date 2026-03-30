import SwiftUI
import NukeUI

struct PhotoGridView: View {
    let photoURLs: [String]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, urlString in
                if let url = URL(string: urlString) {
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minHeight: 120)
                                .clipped()
                        } else if state.error != nil {
                            photoPlaceholder
                        } else {
                            photoPlaceholder
                                .shimmer()
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .cornerRadius(EliteRadius.small)
                }
            }
        }
    }

    private var photoPlaceholder: some View {
        Rectangle()
            .fill(Color.eliteSurfaceElevated)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.eliteTextTertiary)
            )
    }
}

// MARK: - Editable Photo Grid
struct EditablePhotoGrid: View {
    @Binding var photoURLs: [String]
    var onAddPhoto: () -> Void
    var onRemovePhoto: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let maxPhotos = 6

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<maxPhotos, id: \.self) { index in
                if index < photoURLs.count {
                    photoCell(at: index)
                } else if index == photoURLs.count {
                    addPhotoCell
                } else {
                    emptyCell
                }
            }
        }
    }

    private func photoCell(at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            if let url = URL(string: photoURLs[index]) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.eliteSurfaceElevated
                    }
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onRemovePhoto(index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.eliteBackground)
                    .frame(width: 22, height: 22)
                    .background(Color.eliteError)
                    .clipShape(Circle())
                    .padding(4)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .aspectRatio(3/4, contentMode: .fit)
        .cornerRadius(EliteRadius.medium)
    }

    private var addPhotoCell: some View {
        Button(action: onAddPhoto) {
            RoundedRectangle(cornerRadius: EliteRadius.medium)
                .fill(Color.eliteSurface)
                .aspectRatio(3/4, contentMode: .fit)
                .overlay(
                    VStack(spacing: EliteSpacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .light))
                        Text("Add")
                            .font(EliteFont.caption())
                    }
                    .foregroundColor(.eliteAccentMuted)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: EliteRadius.medium)
                        .strokeBorder(Color.eliteAccentMuted.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
        }
    }

    private var emptyCell: some View {
        RoundedRectangle(cornerRadius: EliteRadius.medium)
            .fill(Color.eliteSurface.opacity(0.5))
            .aspectRatio(3/4, contentMode: .fit)
    }
}
