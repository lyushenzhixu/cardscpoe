//
//  ScannerView.swift
//  cardscpoe
//
//  扫描界面 - 相机取景框
//

import SwiftUI

struct ScannerView: View {
    var onDismiss: () -> Void
    var onScanComplete: (CardItem) -> Void
    
    @State private var scanMode: ScanMode = .front
    @State private var isScanning = false
    
    enum ScanMode: String, CaseIterable {
        case front = "正面"
        case back = "背面"
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Top Bar
                HStack {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("扫描球星卡")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 48)
                .padding(.bottom, 16)
                
                Spacer()
                
                // Camera Frame
                ZStack(alignment: .center) {
                    ScannerFrameView()
                }
                .frame(height: 380)
                
                Spacer()
                
                // Hint
                Text("自动对焦 · 确保光线充足")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 24)
                
                // Bottom Controls
                HStack(spacing: 36) {
                    Button {} label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.1), lineWidth: 2)
                            )
                    }
                    
                    Button {
                        simulateScan()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.8), lineWidth: 4)
                                .frame(width: 74, height: 74)
                            Circle()
                                .fill(NyxTheme.Color.signalPrimary)
                                .frame(width: 58, height: 58)
                                .shadow(color: NyxTheme.Color.signalPrimary.opacity(0.5), radius: 10)
                        }
                    }
                    .disabled(isScanning)
                    
                    HStack(spacing: 4) {
                        ForEach(ScanMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    scanMode = mode
                                }
                            } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(scanMode == mode ? .black : .white.opacity(0.4))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(scanMode == mode ? NyxTheme.Color.signalPrimary : .white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func simulateScan() {
        isScanning = true
        // 模拟 1.5 秒识别
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isScanning = false
            onScanComplete(CardItem.demoLuka)
        }
    }
}

private struct ScannerFrameView: View {
    @State private var scanBeamOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Corner brackets
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let cornerLen: CGFloat = 36
                let stroke: CGFloat = 2.5
                
                Path { path in
                    // TL
                    path.move(to: CGPoint(x: 0, y: cornerLen))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerLen, y: 0))
                    // TR
                    path.move(to: CGPoint(x: w - cornerLen, y: 0))
                    path.addLine(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: w, y: cornerLen))
                    // BL
                    path.move(to: CGPoint(x: 0, y: h - cornerLen))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: cornerLen, y: h))
                    // BR
                    path.move(to: CGPoint(x: w - cornerLen, y: h))
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: w, y: h - cornerLen))
                }
                .stroke(NyxTheme.Color.signalPrimary, lineWidth: stroke)
                .frame(width: 248, height: 348)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(width: 248, height: 348)
            
            // Scan beam
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, NyxTheme.Color.signalPrimary, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .shadow(color: NyxTheme.Color.signalPrimary.opacity(0.8), radius: 8)
                .offset(y: scanBeamOffset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2.2)
                        .repeatForever(autoreverses: true)
                    ) {
                        scanBeamOffset = 140
                    }
                }
            
            // Inner placeholder
            RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusSm)
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .frame(width: 192, height: 292)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("将球星卡放入框内")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.25))
                            .fontWeight(.medium)
                    }
                )
        }
        .frame(width: 248, height: 348)
    }
}

#Preview {
    ScannerView(
        onDismiss: {},
        onScanComplete: { _ in }
    )
}
