import SwiftUI

struct TagChip: View {
    let text: String
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Text(text)
            .font(EliteFont.labelMedium())
            .foregroundColor(isSelected ? .eliteBackground : .eliteAccentMuted)
            .padding(.horizontal, EliteSpacing.sm + 4)
            .padding(.vertical, EliteSpacing.xs + 2)
            .background(isSelected ? Color.eliteAccent : Color.eliteSurfaceElevated)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected ? Color.clear : Color.eliteDivider,
                        lineWidth: 0.5
                    )
            )
            .onTapGesture {
                onTap?()
            }
    }
}

struct TagChipFlow: View {
    let tags: [String]
    var selectedTags: Set<String> = []
    var onTagTap: ((String) -> Void)? = nil

    var body: some View {
        FlowLayout(spacing: EliteSpacing.sm) {
            ForEach(tags, id: \.self) { tag in
                TagChip(
                    text: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    onTagTap?(tag)
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

#Preview {
    TagChipFlow(
        tags: ["Art", "Travel", "Wine", "Architecture", "Photography", "Fine Dining"],
        selectedTags: ["Travel", "Wine"]
    )
    .padding(24)
    .background(Color.eliteBackground)
}
