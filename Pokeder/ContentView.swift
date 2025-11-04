//
//  ContentView.swift
//  Pokeder
//
//  Created by Seth Mosgin on 11/2/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = PokederViewModel()
    
    var body: some View {
        VStack {
            AsyncImage(url: viewModel.currentPokemon?.sprites.front_default)
            if let name = viewModel.currentPokemon?.name {
                Text("\(name.capitalized)")
            } else {
                Text("Who's that pokemon?")
            }
            LikeAndDislikeTray(viewModel: viewModel)
        }
        .padding()
        .onAppear {
            if viewModel.pokeData == nil {
                Task {
                    await viewModel.fetchData()
                }
            }
        }
    }
}

struct LikeAndDislikeTray: View {
    @ObservedObject var viewModel: PokederViewModel
    
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

struct PokemonAPIResponse: Codable {
    var count: Int
    var next: URL?
    var previous: URL?
    var results: [PokemonWrapper]
}

struct PokemonWrapper: Codable {
    var name: String
    var url: URL
}

struct Pokemon: Codable {
    var id: Int
    var name: String
    var abilities: [PokemonAbilityWrapper]
    var cries: PokemonCries
    var sprites: Sprites
    var height: Int
    var moves: [PokemonMoveWrapper]
    var stats: [PokemonStatWrapper]
}

struct PokemonAbilityWrapper: Codable {
    var ability: PokemonAbility
    var is_hidden: Bool //convert this to camelcase?
    var slot: Int
}

struct PokemonAbility: Codable {
    var name: String
    var url: URL
}

struct PokemonCries: Codable {
    var latest: URL
    var legacy: URL
}

struct Sprites: Codable {
    var front_default: URL
}

struct PokemonMoveWrapper: Codable {
    var move: PokemonMove
}

struct PokemonMove: Codable {
    var name: String
    var url: URL
}

struct PokemonStatWrapper: Codable {
    var base_stat: Int //convert to camelcase
    var effort: Int
    var stat: PokemonStat
}

struct PokemonStat: Codable {
    var name: String
    var url: URL
}

@MainActor class PokederViewModel: ObservableObject {
    let apiString = "https://pokeapi.co/api/v2/pokemon/"
    
    @Published var pokeData: PokemonAPIResponse?
    var currentPokemonWrapper: PokemonWrapper?
    @Published var currentPokemon: Pokemon?
    
    private func downloadData() async -> PokemonAPIResponse? {
        do {
            guard let url = URL(string: apiString) else { return nil }
            let (data, response) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(PokemonAPIResponse.self, from: data)
            return decodedData
        } catch {
            //error handling
        }
        return nil
    }
    
    private func downloadPokemonData(url: URL) async -> Pokemon? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(Pokemon.self, from: data)
            return decodedData
        } catch {
            //error handling
        }
        return nil
    }
    
    func fetchData() async {
        pokeData = await downloadData()
        currentPokemonWrapper = pokeData?.results.first
        guard let currentPokemonWrapper = currentPokemonWrapper else { return }
        currentPokemon = await downloadPokemonData(url: currentPokemonWrapper.url)
    }
    
    func likeThatPokemon() async {
        //perform the like action?
        
        //fetch a new pokemon
        await fetchData()
    }
    
    func dislikeThatPokemon() async {
        //perform the like action?
        
        //fetch a new pokemon
        await fetchData()
    }
}

#Preview {
    ContentView()
}
