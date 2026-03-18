import SwiftUI

struct PeriodSelectorView: View {
    let periods: [String]
    @Binding var selected: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<periods.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3)) { selected = i }
                } label: {
                    Text(periods[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selected == i ? .black : CSColor.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            selected == i ? CSColor.signalPrimary : Color.white.opacity(0.05)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

#Preview("PeriodSelectorView") {
    PeriodSelectorView(periods: ["7D", "1M", "3M", "6M", "1Y"], selected: .constant(1))
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
