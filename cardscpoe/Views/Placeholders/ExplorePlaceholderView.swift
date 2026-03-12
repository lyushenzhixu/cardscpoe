//
//  ExplorePlaceholderView.swift
//  cardscpoe
//
//  发现页占位
//

import SwiftUI

struct ExplorePlaceholderView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(NyxTheme.signalPrimary.opacity(0.5))
            Text("发现")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(NyxTheme.textPrimary)
            Text("搜索球员、系列、品牌\n热门排行 · 新品上市")
                .font(.system(size: 14))
                .foregroundStyle(NyxTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NyxTheme.surfacePrimary)
    }
}
