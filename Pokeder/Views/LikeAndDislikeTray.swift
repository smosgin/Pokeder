//
//  LikeAndDislikeTray.swift
//  Pokeder
//
//  Created by Seth Mosgin on 12/5/25.
//
import SwiftUI


struct LikeAndDislikeTray: View {
    @ObservedObject var viewModel: PokederViewModel
    //TODO: - enable or disable buttons if pokemon is loaded or not
    var body: some View {
        HStack {
            Button("Dislike") {
                //perform the dislike action
                
                //refresh the pokemon
                Task {
                    await viewModel.dislikeThatPokemon()
                }
            }
            Spacer()
            Button("Like") {
                //perform the like action
                
                //refresh the pokemon
                Task {
                    await viewModel.likeThatPokemon()
                }
            }
        }
    }
}

#Preview(body: {
    LikeAndDislikeTray(viewModel: PokederViewModel())
})
