//
//  PokederViewModel.swift
//  Pokeder
//
//  Created by Seth Mosgin on 11/18/25.
//

import Foundation
import Combine

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
    @Published var unreadMatches: Int = 0 //TODO: - persist this data somewhere
    @Published var pokemonMatches: [PokemonMatch] = []
    private let pokemonLikedBackPublisher = PassthroughSubject<Pokemon, Never>()
    private var cancellables = Set<AnyCancellable>()
    @Published var moveDetails: Dictionary<String, PokemonMoveDetail> = [:]
    @Published var showErrorBanner: Bool = false
    @Published var errorBannerMessage: String = "Generic error"
    
    init() {
        subscribeToPokemonMatches()
    }
    
    func subscribeToPokemonMatches() {
        pokemonLikedBackPublisher
            .sink { [weak self] pokemon in
                guard let self = self else { return }
                self.unreadMatches += 1
                let match = PokemonMatch(id: UUID(), pokemonId: pokemon.id, isRead: false)
                pokemonMatches.append(match)
            }
            .store(in: &cancellables)
    }
    
    func loadUserDefaults() {
        userData.firstName = UserDefaults.standard.string(forKey: firstNameKey) ?? PokederViewModel.DEFAULT_FIRST_NAME
        userData.lastName = UserDefaults.standard.string(forKey: lastNameKey) ?? PokederViewModel.DEFAULT_LAST_NAME
        userData.email = UserDefaults.standard.string(forKey: emailKey) ?? PokederViewModel.DEFAULT_EMAIL
    }
    
    func initializeApp() {
        if pokeData == nil {
            Task {
                await loadNextPokemon()
            }
        }
        loadLikedAndDislikedPokemon()
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
    
    private func downloadPokemonMoveData(url: URL) async -> PokemonMoveDetail? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(PokemonMoveDetail.self, from: data)
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
    
    //Call loadNextPokemon() from anywhere outside of laodNextPokemon()
    private func fetchPokemonData() async {
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
            await fetchPokemonData()
        } else {
            guard var index = pokeData?.results.firstIndex(where: {($0.name == currentPokemonWrapper?.name)}) else { return }
            index += 1
            currentPokemonWrapper = pokeData?.results[index]
            guard let currentPokemonWrapper = currentPokemonWrapper else { return }
            currentPokemon = await downloadPokemonData(url: currentPokemonWrapper.url)
        }
        downloadPokemonMoveData()
    }
    
    func downloadPokemonMoveData() {
        guard let pokemon = currentPokemon else { return }
        for move in pokemon.moves {
            Task {
                print("Creating task for \(move.move.url)")
                let data = await downloadPokemonMoveData(url: move.move.url)
                moveDetails[move.move.name] = data
            }
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
    
    func determineIfPokemonLikesBack(pokemon: Pokemon) {
        //simulate doing some long logic to figure out if there's a match
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.pokemonLikedBackPublisher.send(pokemon)
        }
    }
    
    func likeThatPokemon() async {
        guard let currentPokemon = currentPokemon else { return }
        //perform the like action?
        savePokemonToFile(LIKED_POKEMON_FILENAME)
        likedPokemon = loadPokemonFromFile(LIKED_POKEMON_FILENAME)
        determineIfPokemonLikesBack(pokemon: currentPokemon)
        
        //fetch a new pokemon
        await loadNextPokemon()
    }
    
    func dislikeThatPokemon() async {
        savePokemonToFile(DISLIKED_POKEMON_FILENAME)
        dislikedPokemon = loadPokemonFromFile(DISLIKED_POKEMON_FILENAME)
        
        //fetch a new pokemon
        await loadNextPokemon()
    }
    
    func showErrorToUser(message: String = "Generic error") {
        errorBannerMessage = message
        showErrorBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            self?.showErrorBanner = false
        })
    }
}
