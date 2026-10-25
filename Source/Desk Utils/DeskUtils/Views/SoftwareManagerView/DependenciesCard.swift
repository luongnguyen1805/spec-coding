import SwiftUI

struct DependenciesCard: View {
    let deps: [String]

    var body: some View {
        CardContainer(title: "Dependencies (\(deps.count))") {
            FlowLayout(spacing: 6) {
                ForEach(deps, id: \.self) { dep in
                    Text(dep)
                        .font(.defaultFont)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
