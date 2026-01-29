import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = CallViewModel()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Status Label
                Text(viewModel.status)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                
                Spacer()
                
                // --- BUTTON AREA ---
                HStack(spacing: 40) {
                    
                    // 1. Connect Button (Always visible if not in call)
                    if viewModel.status == "Disconnected" || viewModel.status == "Server Disconnected" {
                        Button(action: {
                            viewModel.connect()
                        }) {
                            CircularButton(icon: "antenna.radiowaves.left.and.right", color: .blue, text: "Connect")
                        }
                    }
                    
                    // 2. Call Button (Visible if connected & idle)
                    if viewModel.status == "Server Connected" {
                        Button(action: {
                            viewModel.startCall()
                        }) {
                            CircularButton(icon: "phone.fill", color: .green, text: "Call")
                        }
                    }
                    
                    // 3. Answer Button (Visible ONLY when incoming call)
                    if viewModel.hasIncomingCall {
                        Button(action: {
                            viewModel.answerCall()
                        }) {
                            CircularButton(icon: "phone.connection", color: .yellow, text: "Answer")
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// Helper view to make buttons look nice
struct CircularButton: View {
    var icon: String
    var color: Color
    var text: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
            Text(text)
                .font(.caption)
                .bold()
        }
        .frame(width: 90, height: 90)
        .background(color)
        .foregroundColor(.white)
        .clipShape(Circle())
        .shadow(radius: 10)
    }
}
