import SwiftUI
import SwiftData

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIChatMessage.timestamp, order: .reverse) private var messages: [AIChatMessage]
    @EnvironmentObject private var localization: LocalizationManager
    @State private var inputText: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Chat Messages
                if messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        
                        Text(localization.getString("homeAskMessages"))
                            .font(.headline)
                        
                        Text(localization.getString("aiChatHint"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                        }
                        .padding()
                    }
                }
                
                // MARK: - Input Area
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField(localization.getString("aiChatPlaceholder"), text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                        
                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                                    .frame(width: 44, height: 44)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(inputText.isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle(localization.getString("tabAI"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        
        // Simular respuesta (reemplazar con llamada real a API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let userMessage = AIChatMessage(
                role: "user",
                text: inputText,
                timestamp: .now,
                sourceSummary: ""
            )
            modelContext.insert(userMessage)
            
            // Simular respuesta de IA
            let aiResponse = AIChatMessage(
                role: "assistant",
                text: LocalizationManager.shared.getString("aiChatProcessing"),
                timestamp: .now,
                sourceSummary: ""
            )
            modelContext.insert(aiResponse)
            
            inputText = ""
            isLoading = false
        }
    }
}

// MARK: - Chat Bubble Component
struct ChatBubble: View {
    let message: AIChatMessage
    
    var isUser: Bool {
        message.role == "user"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isUser {
                Spacer()
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .padding(12)
                    .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if !message.sourceSummary.isEmpty {
                    Text(message.sourceSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !isUser {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AIChatView()
        .environmentObject(LocalizationManager.shared)
}
