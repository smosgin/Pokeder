//
//  PokederViewModel.swift
//  Pokeder
//
//  Created by Seth Mosgin on 11/18/25.
//

import Foundation

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
