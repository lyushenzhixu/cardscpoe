//
//  ProfilePlaceholderView.swift
//  cardscpoe
//
//  我的页占位
//

import SwiftUI

struct ProfilePlaceholderView: View {
    var onShowPaywall: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(NyxTheme.textSecondary)
            Text("我的")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(NyxTheme.textPrimary)
            Text("账户设置 · 订阅管理 · 识别历史")
                .font(.system(size: 14))
                .foregroundStyle(NyxTheme.textTertiary)
                .multilineTextAlignment(.center)
            
            Button(action: onShowPaywall) {
                Text("订阅 Pro")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(NyxTheme.signalPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NyxTheme.surfacePrimary)
    }
}
