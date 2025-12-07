//
//  PokemonAttackRow.swift
//  Pokeder
//
//  Created by Seth Mosgin on 12/5/25.
//

import SwiftUI

struct PokemonMoveRow: View {
    
    let pokemonMove: PokemonMoveWrapper
    let pokemonMoveType: String
    
    var body: some View {
        HStack {
            Text("\(pokemonMove.move.name)".capitalized)
            Spacer()
            Text("\(pokemonMoveType)".capitalized)
        }
    }
}

#Preview {
    let move = PokemonMove(name: "First move", url: URL(string: "https://www.google.com")!)
    let details = [PokemonVersionGroupDetails(levelLearnedAt: 3)]
    let moveDetail = PokemonMoveDetail(id: 5, name: "First move", damageClass: PokemonMoveDamageClass(name: "physical", url: URL(string: "https://pokeapi.co/api/v2/type/1/")!), type: PokemonMoveType(name: "normal", url: URL(string: "https://pokeapi.co/api/v2/type/1/")!))
    PokemonMoveRow(pokemonMove: PokemonMoveWrapper(move: move, versionGroupDetails: details), pokemonMoveType: "moveTypeString")
}
