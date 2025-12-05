//
//  PokemonBioCard.swift
//  Pokeder
//
//  Created by Seth Mosgin on 12/5/25.
//
import SwiftUI


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
                Section("Abilities") {
                    ForEach(abilities) { ability in
                        Text(ability.ability.name)
                    }
                }
            }
            List() {
                Section("Moves") {
                    ForEach(moves) { move in
                        Text(move.move.name)
                    }
                }
            }
            List {
                Section("Stats") {
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
}

#Preview {
    PokemonBioCard(viewModel: PokederViewModel())
}
