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
                Button("User Profile", systemImage: "person.circle") {
                    isProfilePresented.toggle()
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

struct Pokemon: Codable, Equatable, Identifiable {
    var id: Int
    var name: String
    var abilities: [PokemonAbilityWrapper]
    var cries: PokemonCries
    var sprites: Sprites
    var height: Int
    var weight: Int
    var moves: [PokemonMoveWrapper]
    var stats: [PokemonStatWrapper]
    
    static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PokemonAbilityWrapper: Codable, Identifiable {
    var id = UUID()
    var ability: PokemonAbility
    var isHidden: Bool
    var slot: Int
    
    enum CodingKeys: String, CodingKey {
        case ability, slot
        case isHidden = "is_hidden"
    }
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

struct PokemonMoveWrapper: Codable, Identifiable {
    var id = UUID()
    var move: PokemonMove
    
    enum CodingKeys: String, CodingKey {
        case move
    }
}

struct PokemonMove: Codable {
    var name: String
    var url: URL
}

struct PokemonStatWrapper: Codable, Identifiable {
    var id = UUID()
    var baseStat: Int
    var effort: Int
    var stat: PokemonStat
    
    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case effort, stat
    }
}

struct PokemonStat: Codable {
    var name: String
    var url: URL
}

struct UserProfile: Codable {
    var firstName: String
    var lastName: String
    var email: String
}

@MainActor class PokederViewModel: ObservableObject {
    let apiString = "https://pokeapi.co/api/v2/pokemon/"
    let firstNameKey = "fname"
    static let DEFAULT_FIRST_NAME = "Ash"
    let lastNameKey = "lname"
    static let DEFAULT_LAST_NAME = "Ketchum"
    let emailKey = "email"
    static let DEFAULT_EMAIL = "ash@example.com"
    let LIKED_POKEMON_FILENAME = "likedPokemon.json"
    let DISLIKED_POKEMON_FILENAME = "dislikedPokemon.json"
    
    var userData: UserProfile = UserProfile(firstName: DEFAULT_FIRST_NAME, lastName: DEFAULT_LAST_NAME, email: DEFAULT_EMAIL)
    
    @Published var pokeData: PokemonAPIResponse?
    var currentPokemonWrapper: PokemonWrapper?
    @Published var currentPokemon: Pokemon?
    @Published var likedPokemon: [Pokemon]?
    @Published var dislikedPokemon: [Pokemon]?
    
    func loadUserDefaults() {
        userData.firstName = UserDefaults.standard.string(forKey: firstNameKey) ?? PokederViewModel.DEFAULT_FIRST_NAME
        userData.lastName = UserDefaults.standard.string(forKey: lastNameKey) ?? PokederViewModel.DEFAULT_LAST_NAME
        userData.email = UserDefaults.standard.string(forKey: emailKey) ?? PokederViewModel.DEFAULT_EMAIL
    }
    
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
            print(error.localizedDescription)
        }
        return nil
    }
    
    func loadLikedAndDislikedPokemon() {
        likedPokemon = loadPokemonFromFile(LIKED_POKEMON_FILENAME)
        dislikedPokemon = loadPokemonFromFile(DISLIKED_POKEMON_FILENAME)
    }
    
    func fetchData() async {
        if pokeData == nil {
            guard let url = URL(string: apiString) else { return }
            pokeData = await downloadData(url: url)
        } else {
            guard let url = pokeData?.next else { return } //TODO: i think this will cause the like button to not do anything once we reach the end of the list of pokemon, eventually
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
    
    func loadPokemonFromFile(_ filename: String) -> [Pokemon]? {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = directory.appending(path: filename, directoryHint: .notDirectory)
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode([Pokemon].self, from: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func savePokemonToFile(_ filename: String) {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                let currentPokemon = currentPokemon
        else { return }
        let fileURL = directory.appending(path: filename, directoryHint: .notDirectory)
        let encoder = JSONEncoder()
        var existingPokemon = loadPokemonFromFile(filename) ?? [] //maybe unnecessary if we check for existingpokemon first elsewhere?
        if existingPokemon.contains(currentPokemon) == true {
            print("pokemon already in file")
            return
        }
        existingPokemon.append(currentPokemon)
        do {
            let data = try encoder.encode(existingPokemon)
            try data.write(to: fileURL)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func likeThatPokemon() async {
        //perform the like action?
        savePokemonToFile(LIKED_POKEMON_FILENAME)
        likedPokemon = loadPokemonFromFile(LIKED_POKEMON_FILENAME)
        
        //fetch a new pokemon
        await loadNextPokemon()
    }
    
    func dislikeThatPokemon() async {
        savePokemonToFile(DISLIKED_POKEMON_FILENAME)
        dislikedPokemon = loadPokemonFromFile(DISLIKED_POKEMON_FILENAME)
        
        //fetch a new pokemon
        await loadNextPokemon()
    }
}

#Preview {
    ContentView()
}
