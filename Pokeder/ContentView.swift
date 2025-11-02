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
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("\(viewModel.pokeData?.name)")
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
    @Binding var imageId: UUID
    
    var body: some View {
        HStack {
            Button("Like") {
                //perform the like action
                
                //refresh the pokemon
                imageId = UUID()
            }
            Spacer()
            Button("Dislike") {
                //perform the dislike action
                
                //refresh the pokemon
                imageId = UUID()
            }
        }
    }
}

struct Pokemon: Codable {
    var id: Int
    var name: String
    var height: Int
}

@MainActor class PokederViewModel: ObservableObject {
    let apiString = "https://pokeapi.co/api/v2/pokemon/"
    let MAX_ID = 1328
    
    @Published var pokeData: Pokemon?
    
    private func downloadData() async -> Pokemon? {
        do {
            let randomId = Int.random(in: 1...MAX_ID)
            guard let url = URL(string: apiString + "\(randomId)") else { return nil }
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
    }
}

#Preview {
    ContentView()
}
