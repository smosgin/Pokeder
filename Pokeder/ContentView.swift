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
            PokemonBioCard(viewModel: viewModel)
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

struct PokemonBioCard: View {
    @ObservedObject var viewModel: PokederViewModel
    
    var body: some View {
        let height = viewModel.currentPokemon?.height ?? -1
        let weight = viewModel.currentPokemon?.weight ?? -1
        VStack {
            HStack {
                Text("Height: \(height) decimeters")
                Spacer()
                Text("Weight: \(weight) hectograms")
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
    var weight: Int
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
    
    private func downloadData(url: URL) async -> PokemonAPIResponse? {
        do {
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
        if pokeData == nil {
            guard let url = URL(string: apiString) else { return }
            pokeData = await downloadData(url: url)
        } else {
            guard let url = pokeData?.next else { return } //i think this will cause the like button to not do anything once we reach the end of the list of pokemon, eventually
            pokeData = await downloadData(url: url)
        }
        currentPokemonWrapper = pokeData?.results.first
        guard let currentPokemonWrapper = currentPokemonWrapper else { return }
        currentPokemon = await downloadPokemonData(url: currentPokemonWrapper.url)
    }
    
    func isRefreshNeeded() -> Bool {
        guard let pokeData = pokeData else { return true }
        guard let currentPokemonWrapper = currentPokemonWrapper else { return true }
        
        if currentPokemonWrapper.name == pokeData.results.last?.name {
            return true
        } else {
            return false
        }
    }
    
    func loadNextPokemon() async {
        if isRefreshNeeded() {
            await fetchData()
        } else {
            guard var index = pokeData?.results.firstIndex(where: {($0.name == currentPokemonWrapper?.name)}) else { return }
            index += 1
            currentPokemonWrapper = pokeData?.results[index]
            guard let currentPokemonWrapper = currentPokemonWrapper else { return }
            currentPokemon = await downloadPokemonData(url: currentPokemonWrapper.url)
        }
    }
    
    func likeThatPokemon() async {
        //perform the like action?
        
        //fetch a new pokemon
        await loadNextPokemon()
    }
    
    func dislikeThatPokemon() async {
        //perform the like action?
        
        //fetch a new pokemon
        await loadNextPokemon()
    }
}

#Preview {
    ContentView()
}
