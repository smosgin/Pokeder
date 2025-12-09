//
//  ErrorBannerView.swift
//  Pokeder
//
//  Created by Seth Mosgin on 12/6/25.
//

import SwiftUI

struct ErrorBannerView: View {
    
    let message: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack {
            if isVisible {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text(message)
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 70)
                .background(Color.red.ignoresSafeArea(edges: .top))
                .foregroundStyle(.white)
                .transition(
                    .asymmetric(
                        insertion: .push(from: .top),
                        removal: .push(from: .bottom)
                    )
                )
            }
        }
        .animation(.linear, value: isVisible)
    }
}

#Preview {
    @Previewable @State var isVisible: Bool = false
    ContentView(viewModel: PokederViewModel())
        .overlay(alignment: .top) {
            ErrorBannerView(message: "ERRORRRRRRR", isVisible: $isVisible)
        }
    Button("Test alert") {
        isVisible.toggle()
    }
}
