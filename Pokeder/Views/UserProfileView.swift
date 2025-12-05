//
//  UserProfileView.swift
//  Pokeder
//
//  Created by Seth Mosgin on 12/5/25.
//

import SwiftUI


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

#Preview(body: {
    UserProfileView(viewModel: PokederViewModel(), isPresented: .constant(true))
})
