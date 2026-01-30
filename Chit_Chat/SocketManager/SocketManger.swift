import Foundation
import SocketIO
import WebRTC

protocol SignalingClientDelegate: AnyObject {
    func signalingClientDidConnect(_ client: SignalingClient)
    func signalingClientDidDisconnect(_ client: SignalingClient)
    func signalingClient(_ client: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalingClient(_ client: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
}

class SignalingClient {
    private let manager: SocketManager
    private let socket: SocketIOClient
    weak var delegate: SignalingClientDelegate?
    private let roomName = "room1"

    init() {
       
        let url = URL(string: "https://d5042663e928.ngrok-free.app")!

        self.manager = SocketManager(socketURL: url, config: [.log(true), .compress, .forceWebsockets(true)])
        self.socket = manager.defaultSocket
        
        setupListeners()
    }
    
    func connect() {
        socket.connect()
    }
    
    private func setupListeners() {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print(" Socket Connected")
            guard let self = self else { return }
            self.delegate?.signalingClientDidConnect(self)
            self.socket.emit("join", self.roomName)
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print(" Socket Disconnected")
            self?.delegate?.signalingClientDidDisconnect(self!)
        }
        
        socket.on("offer") { [weak self] data, _ in
            self?.handleSdp(data: data, type: .offer)
        }
        
        socket.on("answer") { [weak self] data, _ in
            self?.handleSdp(data: data, type: .answer)
        }
        
        socket.on("ice-candidate") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let sdp = dict["candidate"] as? String,
                  let sdpMid = dict["sdpMid"] as? String,
                  let sdpMLineIndex = dict["sdpMLineIndex"] as? Int32 else { return }
            
            let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
            self.delegate?.signalingClient(self, didReceiveCandidate: candidate)
        }
    }
    
    private func handleSdp(data: [Any], type: RTCSdpType) {
        guard let dict = data.first as? [String: Any],
              let sdp = dict["sdp"] as? String else { return }
        
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)
        self.delegate?.signalingClient(self, didReceiveRemoteSdp: sessionDescription)
    }
    
    func send(sdp: RTCSessionDescription) {
        let typeString = (sdp.type == .offer) ? "offer" : "answer"
        let sdpData: [String: Any] = [
            "type": typeString,
            "sdp": sdp.sdp
        ]
        socket.emit(typeString, sdpData, roomName)
    }
    
    func send(candidate: RTCIceCandidate) {
        let candidateData: [String: Any] = [
            "candidate": candidate.sdp,
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": candidate.sdpMLineIndex
        ]
        socket.emit("ice-candidate", candidateData, roomName)
    }
}
