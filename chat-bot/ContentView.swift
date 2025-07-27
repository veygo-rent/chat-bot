//
//  ContentView.swift
//  chat-bot
//
//  Created by Shenghong Zhou on 7/27/25.
//

import SwiftUI
import FoundationModels

struct ContentView: View {
    @State var prompt: String = ""
    @State var result: String = ""
    let session = LanguageModelSession()
    var body: some View {
        ScrollView {
            VStack (spacing: 20) {
                TextField("Enter a prompt", text: $prompt)
                Text("Result: \(result)")
                HStack {
                    Button {
                        prompt = ""
                    } label: {
                        Text("Clear")
                    }
                    Button {
                        result = "Loading..."
                        Task {
                            do {
                                let response = try await session.respond(to: prompt)
                                result = response.content
                            } catch {
                                result = "Error: \(error.localizedDescription)"
                            }
                        }
                    } label: {
                        Text("Ask")
                    }
                }

            }.padding(20)
        }
    }
}

#Preview {
    ContentView()
}
