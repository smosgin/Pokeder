//
//  ContentView.swift
//  Pokeder
//
//  Created by Seth Mosgin on 11/2/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = PokederViewModel()
    @State private var isProfilePresented = false
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        NavigationStack {
            VStack { 
                AsyncImage(url: viewModel.currentPokemon?.sprites.front_default)
                if let name = viewModel.currentPokemon?.name {
                    Text("\(name.capitalized)")
                } else {
                    Text("Who's that pokemon?")
                }
                PokemonBioCard(viewModel: viewModel)
                LikeAndDislikeTray(viewModel: viewModel)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isProfilePresented.toggle()
                    } label: {
                        let notificationCount = viewModel.unreadMatches
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "person.circle")
                                .font(.title2)
                            if notificationCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(.red)
                                    Text(notificationCount > 99 ? "99+" : "\(notificationCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: notificationCount > 9 ? 20 : 18, height: notificationCount > 9 ? 20 : 18)
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
            .popover(isPresented: $isProfilePresented) {
                UserProfileView(viewModel: viewModel, isPresented: $isProfilePresented)
            }
            .onAppear {
                initializeApp()
            }
            .offset(dragOffset)
            .animation(.interactiveSpring, value: dragOffset)
        }
        .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onEnded({ value in
                dragGestureLogic(value: value)
            })
            .onChanged({ value in
                dragOffset = value.translation
            })
        )
    }
    
    func initializeApp() {
        viewModel.initializeApp()
    }
    
    func dragGestureLogic(value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        
        if abs(horizontalAmount) > abs(verticalAmount) {
            if abs(horizontalAmount) > 100 {
                dragOffset = .zero
                if horizontalAmount < 0 {
                    Task {
                        await viewModel.dislikeThatPokemon()
                    }
                } else {
                    Task {
                        await viewModel.likeThatPokemon()
                    }
                }
            } else {
                withAnimation(.spring) {
                    dragOffset = .zero
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
