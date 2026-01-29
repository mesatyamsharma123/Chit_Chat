import Foundation
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
}

class WebRTCClient: NSObject {
    
    // The Factory creates connections
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    private var peerConnection: RTCPeerConnection?
    weak var delegate: WebRTCClientDelegate?
    
    override init() {
        super.init()
        setupPeerConnection()
    }
    
    // MARK: - Setup
    private func setupPeerConnection() {
        let config = RTCConfiguration()
        // STUN servers let you punch through firewalls
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.sdpSemantics = .unifiedPlan
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        
        self.peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: self)
        
        createLocalAudioTrack()
    }
    
    private func createLocalAudioTrack() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: constraints)
        let audioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: "audio0")
        
        // Add the audio track to the connection
        self.peerConnection?.add(audioTrack, streamIds: ["stream0"])
    }
    
    // MARK: - Signaling Actions
    
    func offer(completion: @escaping (RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)
        
        peerConnection?.offer(for: constraints, completionHandler: { (sdp, error) in
            guard let sdp = sdp else { return }
            self.peerConnection?.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        })
    }
    
    func answer(completion: @escaping (RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)
        
        peerConnection?.answer(for: constraints, completionHandler: { (sdp, error) in
            guard let sdp = sdp else { return }
            self.peerConnection?.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        })
    }
    
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        peerConnection?.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func set(remoteCandidate: RTCIceCandidate) {
        peerConnection?.add(remoteCandidate)
    }
}

// MARK: - WebRTC Delegates
// MARK: - WebRTC Delegates
extension WebRTCClient: RTCPeerConnectionDelegate {
    
    // 1. Signaling state changed (Required)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling State Changed: \(stateChanged.rawValue)")
    }
    
    // 2. Media stream added (Required)
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Stream Added")
    }
    
    // 3. Media stream removed (Required)
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Stream Removed")
    }
    
    // 4. Should negotiate (Required)
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Should Negotiate")
    }
    
    // 5. ICE Connection state changed (Required & Used)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE Connection State: \(newState.rawValue)")
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    // 6. ICE Gathering state changed (Required)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE Gathering State Changed: \(newState.rawValue)")
    }
    
    // 7. Generated ICE Candidate (Required & Used)
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("Generated Candidate")
        self.delegate?.webRTCClient(self, didGenerate: candidate)
    }
    
    // 8. Remove ICE Candidates (Required)
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("Removed Candidates")
    }
    
    // 9. Data Channel (Required)
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data Channel Opened")
    }
}
