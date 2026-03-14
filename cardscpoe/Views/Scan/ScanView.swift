import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var cameraManager = CameraManager()
    @State private var isAnalyzing = false
    @State private var showFlash = false
    @State private var selectedMode = 0
    @State private var showingImagePicker = false

    var body: some View {
        ZStack {
            CSColor.surfacePrimary.ignoresSafeArea()

            cameraBackground

            topBar

            centerFrame

            bottomControls

            if isAnalyzing {
                analyzingOverlay
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                Task { await processCapturedImage(image) }
            }
        }
        .task {
            await cameraManager.requestPermissionAndConfigure()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    private var cameraBackground: some View {
        Group {
            if cameraManager.authorizationGranted {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.12),
                        Color(red: 0.03, green: 0.03, blue: 0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CSColor.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(CSColor.surfaceElevated)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(CSColor.border, lineWidth: 0.5))
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11))
                    Text("Card Scanner")
                        .font(CSFont.caption(.semibold))
                }
                .foregroundStyle(CSColor.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(CSColor.surfaceElevated)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(CSColor.border, lineWidth: 0.5))

                Spacer()

                Button {
                    showFlash.toggle()
                } label: {
                    Image(systemName: showFlash ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(showFlash ? CSColor.signalGold : CSColor.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(CSColor.surfaceElevated)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(CSColor.border, lineWidth: 0.5))
                }
            }
            .padding(.horizontal, CSSpacing.md)
            .padding(.top, 50)

            Spacer()
        }
    }

    private var centerFrame: some View {
        VStack {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: CSRadius.sm)
                    .stroke(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundStyle(Color.white.opacity(0.06))
                    .frame(width: 200, height: 280)

                placeholderOverlay

                ViewfinderFrame(color: CSColor.signalPrimary)
                    .frame(width: 248, height: 348)

                ScanBeamView()
                    .frame(width: 230, height: 330)
            }

            Text("Auto-detect · \(Text("Good lighting").foregroundStyle(CSColor.signalPrimary))")
                .font(CSFont.body(.medium))
                .foregroundStyle(CSColor.textTertiary)

            Spacer()
                .frame(height: 140)
        }
    }

    private var placeholderOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                .frame(width: 200, height: 280)

            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundStyle(Color.white.opacity(0.16))
                .frame(width: 182, height: 262)

            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.white.opacity(0.14))

            VStack {
                Spacer()
                Text("Place card in frame")
                    .font(CSFont.caption(.medium))
                    .foregroundStyle(CSColor.textTertiary)
                    .padding(.bottom, 10)
            }
            .frame(width: 200, height: 280)
        }
    }

    private var bottomControls: some View {
        VStack {
            Spacer()

            HStack {
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                        .foregroundStyle(CSColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(CSColor.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: CSRadius.sm)
                                .stroke(CSColor.border, lineWidth: 0.5)
                        )
                }

                Spacer()

                Button {
                    capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 3)
                            .frame(width: 68, height: 68)
                        Circle()
                            .fill(CSColor.signalPrimary)
                            .frame(width: 54, height: 54)
                            .shadow(color: CSColor.signalPrimary.opacity(0.3), radius: 10)
                    }
                }
                .buttonStyle(NyxPressableStyle())

                Spacer()

                HStack(spacing: CSSpacing.xs) {
                    modeButton("Front", index: 0)
                    modeButton("Back", index: 1)
                }
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 40)
        }
    }

    private func modeButton(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedMode = index }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(selectedMode == index ? .black : CSColor.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selectedMode == index ? CSColor.signalPrimary : CSColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedMode == index ? CSColor.signalPrimary : CSColor.border, lineWidth: 0.5)
                )
        }
    }

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: CSSpacing.md) {
                ProgressView()
                    .tint(CSColor.signalPrimary)
                    .scaleEffect(1.5)

                Text("Analyzing card...")
                    .font(CSFont.headline(.semibold))
                    .foregroundStyle(CSColor.textPrimary)

                Text("AI identification in progress")
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textSecondary)
            }
            .padding(CSSpacing.xl)
            .nyxCard()
        }
    }

    private func capturePhoto() {
        Task {
            isAnalyzing = true
            if cameraManager.authorizationGranted {
                if let image = try? await cameraManager.capturePhoto() {
                    await processCapturedImage(image)
                } else {
                    appState.simulateScanNoResult()
                    isAnalyzing = false
                    dismiss()
                }
            } else {
                appState.simulateScanNoResult()
                isAnalyzing = false
                dismiss()
            }
        }
    }

    @MainActor
    private func processCapturedImage(_ image: UIImage) async {
        isAnalyzing = true
        await appState.scan(image: image, context: modelContext)
        isAnalyzing = false
        dismiss()
    }
}
