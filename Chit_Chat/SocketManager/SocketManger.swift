//
//  SocketManger.swift
//  Chit_Chat
//
//  Created by Satyam Sharma Chingari on 29/01/26.
//

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
    
    // Replace with your actual room name logic if needed
    private let roomName = "room1"

    init() {
        // 1. Setup the Socket Manager with your ngrok URL
        // We use .forceWebsockets(true) to ensure it works smoothly with ngrok
        let url = URL(string: "https://5d9c1d177d80.ngrok-free.app")!
        self.manager = SocketManager(socketURL: url, config: [.log(true), .compress, .forceWebsockets(true)])
        self.socket = manager.defaultSocket
        
        setupListeners()
    }
    
    func connect() {
        socket.connect()
    }
    
    private func setupListeners() {
        // Connected to Server
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ Connected to Signaling Server")
            guard let self = self else { return }
            self.delegate?.signalingClientDidConnect(self)
            
            // Immediately join the room upon connection
            self.socket.emit("join", self.roomName)
        }
        
        // Handle "ready" (Both users are in room -> Caller triggers Offer)
        socket.on("ready") { [weak self] _, _ in
            print("🚀 Ready to start call")
            // In a real app, you might use a delegate here to tell the ViewModel to start the Offer
            // For now, we assume the user triggers it manually or the logic is handled elsewhere
        }
        
        // Handle Incoming SDP (Offer or Answer)
        socket.on("offer") { [weak self] data, _ in
            self?.handleSdp(data: data, type: .offer)
        }
        
        socket.on("answer") { [weak self] data, _ in
            self?.handleSdp(data: data, type: .answer)
        }
        
        // Handle Incoming ICE Candidate
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
    
    // Helper to parse SDP
    private func handleSdp(data: [Any], type: RTCSdpType) {
        guard let dict = data.first as? [String: Any],
              let sdp = dict["sdp"] as? String else { return }
        
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)
        self.delegate?.signalingClient(self, didReceiveRemoteSdp: sessionDescription)
    }
    
    // MARK: - Sending Functions
    
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
