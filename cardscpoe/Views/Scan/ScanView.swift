import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var cameraManager = CameraManager()
    @State private var isAnalyzing = false
    @State private var showFlash = false
    @State private var showingImagePicker = false
    @State private var activeScanMode: ScanMode = .normal

    var body: some View {
        ZStack {
            CSColor.surfacePrimary.ignoresSafeArea()

            cameraBackground

            topBar

            if !isAnalyzing {
                centerFrame
            }

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
        ZStack {
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

            // Frozen image overlay — covers live preview when captured
            if let frozen = cameraManager.frozenImage {
                Image(uiImage: frozen)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .transition(.identity)
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

                // Normal Scan button
                Button {
                    capturePhoto(mode: .normal)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.7), lineWidth: 3)
                                .frame(width: 62, height: 62)
                            Circle()
                                .fill(isAnalyzing ? Color.gray : Color.white)
                                .frame(width: 48, height: 48)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.black)
                        }
                        Text("Scan")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CSColor.textSecondary)
                    }
                }
                .buttonStyle(NyxPressableStyle())
                .disabled(isAnalyzing)

                Spacer()
                    .frame(width: 20)

                // AI Scan button
                Button {
                    capturePhoto(mode: .ai)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(CSColor.signalPrimary.opacity(0.7), lineWidth: 3)
                                .frame(width: 62, height: 62)
                            Circle()
                                .fill(isAnalyzing ? Color.gray : CSColor.signalPrimary)
                                .frame(width: 48, height: 48)
                                .shadow(color: CSColor.signalPrimary.opacity(0.3), radius: 10)
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.black)
                        }
                        HStack(spacing: 2) {
                            Text("AI Scan")
                                .font(.system(size: 10, weight: .semibold))
                            Text("PRO")
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(CSColor.signalPrimary)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .foregroundStyle(CSColor.signalPrimary)
                    }
                }
                .buttonStyle(NyxPressableStyle())
                .disabled(isAnalyzing)

                Spacer()
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 40)
        }
    }

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: CSSpacing.md) {
                ProgressView()
                    .tint(CSColor.signalPrimary)
                    .scaleEffect(1.5)

                Text(activeScanMode == .ai ? "AI analyzing card & grade..." : "Identifying card...")
                    .font(CSFont.headline(.semibold))
                    .foregroundStyle(CSColor.textPrimary)

                Text(activeScanMode == .ai ? "AI grade assessment in progress" : "AI identification in progress")
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textSecondary)
            }
            .padding(CSSpacing.xl)
            .nyxCard()
        }
    }

    // MARK: - Capture & Process

    private func capturePhoto(mode: ScanMode) {
        guard !isAnalyzing else { return }
        if mode == .ai {
            guard appState.subscription.hasGradeAssessment() else {
                appState.presentPaywall(source: .valueUnlock)
                return
            }
        }
        activeScanMode = mode
        Task {
            isAnalyzing = true
            if cameraManager.authorizationGranted {
                if let fullImage = try? await cameraManager.capturePhoto() {
                    let croppedImage = fullImage.croppedToCardFrame()
                    await processCapturedImage(croppedImage, mode: mode)
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
    private func processCapturedImage(_ image: UIImage, mode: ScanMode = .normal) async {
        isAnalyzing = true
        await appState.scan(image: image, mode: mode, context: modelContext)
        isAnalyzing = false
        cameraManager.unfreezePreview()
        dismiss()
    }
}

#Preview("ScanView") {
    PreviewContainer {
        ScanView()
    }
}
