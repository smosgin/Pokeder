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
        }
    }
    
    func initializeApp() {
        if viewModel.pokeData == nil {
            Task {
                await viewModel.fetchData()
            }
        }
        viewModel.loadLikedAndDislikedPokemon()
    }
}

struct UserProfileView: View {
    @ObservedObject var viewModel: PokederViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Text("Hey there, user!")
            List {
                Section("Pokemon that like you back!") {
                    ForEach(viewModel.pokemonMatches) { pokemon in
                        Text("Pokemon with ID:\(pokemon.pokemonId) likes you back!")
                    }
                }
            }
            List {
                Section("Your liked pokemon") {
                    let likedPokemon = viewModel.likedPokemon ?? []
                    ForEach(likedPokemon) { pokemon in
                        Text("\(pokemon.name) pokemon")
                    }
                }
            }
            List {
                Section("Your disliked pokemon") {
                    let dislikedPokemon = viewModel.dislikedPokemon ?? []
                    ForEach(dislikedPokemon) { pokemon in
                        Text("\(pokemon.name) pokemon")
                    }
                }
            }
            .toolbar {
                Button("Done") {
                    isPresented.toggle()
                }
            }
        }
    }
}

struct PokemonBioCard: View {
    @ObservedObject var viewModel: PokederViewModel
    
    var body: some View {
        let height = viewModel.currentPokemon?.height ?? -1
        let weight = viewModel.currentPokemon?.weight ?? -1
        let abilities = viewModel.currentPokemon?.abilities ?? []
        let moves = viewModel.currentPokemon?.moves ?? []
        let stats = viewModel.currentPokemon?.stats ?? []
        VStack {
            HStack {
                Text("Height: \(height) decimeters")
                Spacer()
                Text("Weight: \(weight) hectograms")
            }
            List {
                ForEach(abilities) { ability in
                    Text(ability.ability.name)
                }
            }
            List {
                ForEach(moves) { move in
                    Text(move.move.name)
                }
            }
            List {
                ForEach(stats) { stat in
                    HStack {
                        Text(stat.stat.name)
                        Text(stat.baseStat.description)
                    }
                }
            }
        }
    }
}

struct LikeAndDislikeTray: View {
    @ObservedObject var viewModel: PokederViewModel
    //TODO: - enable or disable buttons if pokemon is loaded or not
    var body: some View {
        HStack {
            Button("Like") {
                //perform the like action
                
                //refresh the pokemon
                Task {
                    await viewModel.likeThatPokemon()
                }
            }
            Spacer()
            Button("Dislike") {
                //perform the dislike action
                
                //refresh the pokemon
                Task {
                    await viewModel.dislikeThatPokemon()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

#Preview(body: {
    UserProfileView(viewModel: PokederViewModel(), isPresented: .constant(true))
})
