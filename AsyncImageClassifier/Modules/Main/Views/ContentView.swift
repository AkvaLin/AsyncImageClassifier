//
//  ContentView.swift
//  AsyncImageClassifier
//
//  Created by Никита Пивоваров on 04.03.2024.
//

import SwiftUI

struct ContentView: View {
    
    let controller = AsyncController()
    
    var body: some View {
        VStack {
            Button("Start") {
                controller.getResult()
            }
            Button("Rename") {
                controller.rename()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
