//
//  PokederModels.swift
//  Pokeder
//
//  Created by Seth Mosgin on 11/18/25.
//
import Foundation

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
    var versionGroupDetails: [PokemonVersionGroupDetails]
    
    enum CodingKeys: String, CodingKey {
        case move
        case versionGroupDetails = "version_group_details"
    }
}

struct PokemonVersionGroupDetails: Codable {
    var levelLearnedAt: Int
    
    enum CodingKeys: String, CodingKey {
        case levelLearnedAt = "level_learned_at"
    }
}

struct PokemonMove: Codable {
    var name: String
    var url: URL
}

struct PokemonMoveDetail: Codable {
    var id: Int
    var name: String
    var damageClass: PokemonMoveDamageClass
    var type: PokemonMoveType
    
    enum CodingKeys: String, CodingKey {
        case id, name, type
        case damageClass = "damage_class"
    }
}

struct PokemonMoveDamageClass: Codable {
    var name: String
    var url: URL
}

struct PokemonMoveType: Codable {
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

struct PokemonMatch: Codable, Identifiable {
    var id: UUID
    var pokemonId: Int
    var isRead: Bool
}
