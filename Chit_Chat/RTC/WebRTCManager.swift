import Foundation
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
}

class WebRTCClient: NSObject {
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        return RTCPeerConnectionFactory()
    }()
    
    private var peerConnection: RTCPeerConnection?
    weak var delegate: WebRTCClientDelegate?
    
    override init() {
        super.init()
        setupPeerConnection()
    }
    
    func setupPeerConnection() {
        let config = RTCConfiguration()
        // Use Google's public STUN server
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
        
        self.peerConnection?.add(audioTrack, streamIds: ["stream0"])
    }
    
    func close() {
        peerConnection?.close()
        peerConnection = nil
    }
    
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

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTCClient(self, didGenerate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCIceConnectionState) {
        self.delegate?.webRTCClient(self, didChangeConnectionState: state)
    }
    
    // Required protocol stubs
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange signalingState: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
