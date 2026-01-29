import Foundation
import SwiftUI
import WebRTC
import Combine

class CallViewModel: ObservableObject {
    private let signalingClient = SignalingClient()
    private let webRTCClient = WebRTCClient()
    
    @Published var status = "Disconnected"
    @Published var hasIncomingCall = false
    
    private var pendingOffer: RTCSessionDescription?
    // Buffer for candidates arriving before remote description is set
    private var remoteCandidatesBuffer: [RTCIceCandidate] = []
    
    init() {
        signalingClient.delegate = self
        webRTCClient.delegate = self
    }
    
    func connect() {
        status = "Connecting..."
        signalingClient.connect()
    }
    
    func startCall() {
        status = "Calling..."
        webRTCClient.offer { [weak self] sdp in
            self?.signalingClient.send(sdp: sdp)
        }
    }
    
    func answerCall() {
        guard let offer = pendingOffer else { return }
        hasIncomingCall = false
        status = "Connecting Audio..."
        
        webRTCClient.set(remoteSdp: offer) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Error setting remote SDP: \(error)")
                return
            }
            
            // Apply any buffered candidates now that remote description is set
            self.drainRemoteCandidates()
            
            self.webRTCClient.answer { answerSdp in
                self.signalingClient.send(sdp: answerSdp)
                DispatchQueue.main.async { self.status = "Audio Connected!" }
            }
        }
    }
    
    func endCall() {
        webRTCClient.close()
        // Reset connection for next time
        webRTCClient.setupPeerConnection()
        remoteCandidatesBuffer.removeAll()
        pendingOffer = nil
        
        DispatchQueue.main.async {
            self.status = "Server Connected"
            self.hasIncomingCall = false
        }
    }
    
    private func drainRemoteCandidates() {
        for candidate in remoteCandidatesBuffer {
            webRTCClient.set(remoteCandidate: candidate)
        }
        remoteCandidatesBuffer.removeAll()
    }
}

// MARK: - Signaling Delegate
extension CallViewModel: SignalingClientDelegate {
    func signalingClientDidConnect(_ client: SignalingClient) {
        DispatchQueue.main.async { self.status = "Server Connected" }
    }
    
    func signalingClientDidDisconnect(_ client: SignalingClient) {
        DispatchQueue.main.async { self.status = "Server Disconnected" }
    }
    
    func signalingClient(_ client: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        if sdp.type == .offer {
            self.pendingOffer = sdp
            DispatchQueue.main.async {
                self.hasIncomingCall = true
                self.status = "Incoming Call..."
            }
        } else if sdp.type == .answer {
            // We are the caller, we received an answer
            webRTCClient.set(remoteSdp: sdp) { [weak self] error in
                if error == nil {
                    self?.drainRemoteCandidates()
                    DispatchQueue.main.async { self?.status = "Audio Connected!" }
                }
            }
        }
    }
    
    func signalingClient(_ client: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        // Just try setting it immediately. WebRTC is robust enough usually.
        webRTCClient.set(remoteCandidate: candidate)
    }
}

// MARK: - WebRTC Delegate
extension CallViewModel: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate) {
        signalingClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected, .completed: self.status = "Audio Connected!"
            case .disconnected: self.status = "Audio Disconnected"
            case .failed: self.status = "Connection Failed"
            case .closed: self.status = "Call Ended"
            default: break
            }
        }
    }
}
