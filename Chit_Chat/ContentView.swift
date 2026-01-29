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
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                
                Spacer()
                
                HStack(spacing: 40) {
                    
                    // CONNECT
                    if viewModel.status == "Disconnected" || viewModel.status == "Server Disconnected" {
                        Button(action: { viewModel.connect() }) {
                            CircularButton(icon: "antenna.radiowaves.left.and.right", color: .blue, text: "Connect")
                        }
                    }
                    
                    // CALL (Only if server connected and idle)
                    if viewModel.status == "Server Connected" {
                        Button(action: { viewModel.startCall() }) {
                            CircularButton(icon: "phone.fill", color: .green, text: "Call")
                        }
                    }
                    
                    // ANSWER (Only if incoming call)
                    if viewModel.hasIncomingCall {
                        Button(action: { viewModel.answerCall() }) {
                            CircularButton(icon: "phone.connection", color: .green, text: "Answer")
                        }
                    }
                    
                    // END (Visible if calling, ringing, or connected)
                    if viewModel.status == "Calling..." ||
                       viewModel.status == "Incoming Call..." ||
                       viewModel.status == "Audio Connected!" {
                        
                        Button(action: { viewModel.endCall() }) {
                            CircularButton(icon: "phone.down.fill", color: .red, text: "End")
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// Reusable Button Component
struct CircularButton: View {
    var icon: String; var color: Color; var text: String
    var body: some View {
        VStack {
            Image(systemName: icon).font(.system(size: 30))
            Text(text).font(.caption).bold()
        }
        .frame(width: 90, height: 90)
        .background(color)
        .foregroundColor(.white)
        .clipShape(Circle())
        .shadow(radius: 10)
    }
}
