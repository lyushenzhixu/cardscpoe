import SwiftUI

struct AreaChartView: View {
    let data: [PriceHistoryPoint]
    var height: CGFloat = 80
    var color: Color = CSColor.signalPrimary

    var body: some View {
        GeometryReader { geo in
            let points = data
            let maxVal = points.map(\.value).max() ?? 1
            let minVal = points.map(\.value).min() ?? 0
            let range = maxVal - minVal
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Gradient fill area
                Path { path in
                    guard points.count > 1 else { return }
                    let stepX = w / CGFloat(points.count - 1)

                    path.move(to: CGPoint(x: 0, y: h))

                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = range > 0 ? h - CGFloat((point.value - minVal) / range) * (h * 0.85) - h * 0.05 : h * 0.5
                        if index == 0 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            let prevX = CGFloat(index - 1) * stepX
                            let prevPoint = points[index - 1]
                            let prevY = range > 0 ? h - CGFloat((prevPoint.value - minVal) / range) * (h * 0.85) - h * 0.05 : h * 0.5
                            let midX = (prevX + x) / 2
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: midX, y: prevY),
                                control2: CGPoint(x: midX, y: y)
                            )
                        }
                    }

                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05), color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Smooth line
                Path { path in
                    guard points.count > 1 else { return }
                    let stepX = w / CGFloat(points.count - 1)

                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = range > 0 ? h - CGFloat((point.value - minVal) / range) * (h * 0.85) - h * 0.05 : h * 0.5
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            let prevX = CGFloat(index - 1) * stepX
                            let prevPoint = points[index - 1]
                            let prevY = range > 0 ? h - CGFloat((prevPoint.value - minVal) / range) * (h * 0.85) - h * 0.05 : h * 0.5
                            let midX = (prevX + x) / 2
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: midX, y: prevY),
                                control2: CGPoint(x: midX, y: y)
                            )
                        }
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
        .frame(height: height)
    }
}

#Preview("AreaChartView") {
    AreaChartView(data: MockData.priceHistory)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
