//
//  ContentView.swift
//  chat-bot
//
//  Created by Shenghong Zhou on 7/27/25.
//

import UIKit
import SwiftUI
import FoundationModels

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var rating: Rating?     // The response is good or bad
    
    enum Rating {
        case good, bad
    }
}

struct ContentView: View {
    @State private var messages: [Message] = []
    @State private var prompt: String = ""
    @State private var session = LanguageModelSession()
    
    var body: some View {
        VStack {
            HStack {
                Text("Veygo Chat")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: {
                    hapticFeedback(style: .medium)
                    session = LanguageModelSession()
                    messages.removeAll()
                }) {
                    Text("Remove All")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(20)
                }
            }
            .padding(5)
            .padding(.horizontal)
            
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
                                        .contextMenu {
                                            Button(action: {
                                                UIPasteboard.general.string = message.text
                                            }) {
                                                Label("Copy", systemImage: "doc.on.doc")
                                            }
                                        }
                                        .onLongPressGesture {
                                            hapticFeedback(style: .light)
                                        }
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                        .contextMenu {
                                            if message.rating != .good {
                                                Button(action: {
                                                    rateMessage(message: message, rating: .good)
                                                }) {
                                                    Label("Good Rating", systemImage: "hand.thumbsup")
                                                }
                                            }
                                            
                                            if message.rating != .bad {
                                                Button(action: {
                                                    rateMessage(message: message, rating: .bad)
                                                }) {
                                                    Label("Bad Rating", systemImage: "hand.thumbsdown")
                                                }
                                            }
                                            
                                            if message.rating != nil {
                                                Button(role: .destructive, action: {
                                                    clearRating(message: message)
                                                }) {
                                                    Label("Clear Rating", systemImage: "xmark.circle")
                                                }
                                            }
                                            
                                            Button(action: {
                                                UIPasteboard.general.string = message.text
                                            }) {
                                                Label("Copy", systemImage: "doc.on.doc")
                                            }
                                        }
                                        .onLongPressGesture {
                                            hapticFeedback(style: .light)
                                        }
                                    Spacer()
                                }
                                
                                // Show ratings
                                if let rating = message.rating {
                                    Image(systemName: rating == .good ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                        .foregroundColor(rating == .good ? .green : .red)
                                        .padding(4)
                                        .font(.title2)
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
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
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                    .frame(minHeight: 36)

                Button(action: {
                    hapticFeedback(style: .medium)
                    sendMessage()
                }) {
                    Text("Send")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(prompt.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
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
    
    func rateMessage(message: Message, rating: Message.Rating) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].rating = rating
        }
    }
    
    func clearRating(message: Message) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].rating = nil
        }
    }
    
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

#Preview {
    ContentView()
}
