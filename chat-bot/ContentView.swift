//
//  ContentView.swift
//  chat-bot
//
//  Created by Shenghong Zhou on 7/27/25.
//

import SwiftUI
import FoundationModels

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ContentView: View {
    @State private var messages: [Message] = []
    @State private var prompt: String = ""
    let session = LanguageModelSession()
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                TextField("Enter your message", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)

                Button("Send") {
                    sendMessage()
                }
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
    }
    
    func sendMessage() {
        let userMessage = Message(text: prompt, isUser: true)
        messages.append(userMessage)
        let currentPrompt = prompt
        prompt = ""

        Task {
            let loadingMessage = Message(text: "Thinking...", isUser: false)
            messages.append(loadingMessage)
            do {
                let response = try await session.respond(to: currentPrompt)
                messages.removeLast() // Remove "Thinking..."
                messages.append(Message(text: response.content, isUser: false))
            } catch {
                messages.removeLast()
                messages.append(Message(text: "Error: \(error.localizedDescription)", isUser: false))
            }
        }
    }
}

#Preview {
    ContentView()
}
