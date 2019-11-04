import socket from "./socket";

class ChatBase {
  constructor(topic) {
    this.channel = socket.channel(topic, {})
    this.channel.on("message", (payload) => this.handleMessage(JSON.parse(payload.body)))
  }

  start() {
    getUserMedia(document.getElementById("localVideo"), (stream) => this.handleLocalStream(stream))
  }

  handleLocalStream(stream) {
    console.log("Got local stream");
    this.localStream = stream
    this.channel.join()
    this.createPeerConnection()
  }

  createPeerConnection() {
    const iceServers = {
      "iceServers": [{
        "urls": "stun:stun.l.google.com:19302"
      }]
    };

    this.peerConnection = new RTCPeerConnection(iceServers)
    this.peerConnection.addStream(this.localStream)
    this.peerConnection.onicecandidate = (event) => this.handleLocalIceCandidate(event)
    this.peerConnection.onaddstream = (event) => this.handleRemoteStream(event)
  }

  handleMessage(msg) {
    console.log(msg)
    switch(msg.msg_type) {
      case "sdp": return this.handleRemoteSDP(msg.sdp)
      case "ice": return this.handleRemoteIceCandidate(msg.candidate)
    }
  }

  sendMessage(msg) {
    this.channel.push("message", {body: JSON.stringify(msg)})
  }

  handleError(error) {
    console.log(error)
  }

  handleLocalSDP(sdp) {
    console.log("Got local SDP");

    this.peerConnection.setLocalDescription(sdp, () => this.pushLocalSDP(), this.handleError)
  }

  pushLocalSDP() {
    this.sendMessage({msg_type: "sdp", sdp: this.peerConnection.localDescription})
  }

  handleLocalIceCandidate(event) {
    console.log("Got local ICE candidate");

    if (event.candidate) {
      this.sendMessage({msg_type: "ice", candidate: event.candidate})
    }
  }

  handleRemoteStream(event) {
    console.log("Got remote stream");
    playVideoStream(document.getElementById("remoteVideo"), event.stream)
  }

  handleRemoteSDP(sdp) {
    console.log("Got remote SDP");
    this.peerConnection.setRemoteDescription(new RTCSessionDescription(sdp));
  }

  handleRemoteIceCandidate(candidate) {
    console.log("Got remote ICE candidate");
    this.peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
  }

  disconnect() {
    console.log("Disconnect")
    this.channel.leave()
    stopVideoStream(this.localStream)
  }
}

class ChatMale extends ChatBase {
  handleMessage(msg) {
    switch(msg.msg_type) {
      case "start":
        if (this.started) { return }
        this.started = true
        return this.createOffer()
      default: return super.handleMessage(msg)
    }
  }

  createOffer() {
    console.log("Create offer")
    this.peerConnection.createOffer(
      (sdp) => this.handleLocalSDP(sdp),
      this.handleError
    );
  }
}

class ChatFemale extends ChatBase {
  handleMessage(msg) {
    switch(msg.msg_type) {
      case "start":
        this.pushStart()
        break
      default:
        super.handleMessage(msg)
        break
    }
  }

  pushStart() {
    this.sendMessage({msg_type: "start"})
  }

  handleRemoteSDP(sdp) {
    super.handleRemoteSDP(sdp)
    this.peerConnection.createAnswer(
      (sdp) => this.handleLocalSDP(sdp),
      this.handleError
    );
  }
}

let gender, topic, chat

function restartChat() {
  if (chat != null) {
    chat.disconnect()
    chat = null
  }
  switch(gender) {
    case "male":
      chat = new ChatMale(topic)
      return chat.start()
    case "female":
      chat = new ChatFemale(topic)
      return chat.start()
  }
}

function updateChat() {
  let g, t

  let localVideo = document.getElementById("localVideo")
  if (localVideo == null) {
    g = t = null
  } else {
    g = localVideo.getAttribute("data-gender")
    t = localVideo.getAttribute("data-topic")
  }

  if ((g != gender) || (t != topic)) {
    gender = g
    topic = t
    console.log(`Updating chat: gender=${gender} topic=${topic}`)
    restartChat()
  }
}

function stopVideoStream(stream) {
  stream.getTracks().forEach((track) => track.stop())
}

function getUserMedia(video, callback) {
  navigator.mediaDevices.getUserMedia({audio: true, video: {facingMode: "user"}})
    .then((stream) => {
      playVideoStream(video, stream)
      if (callback != null) callback(stream)
    })
    .catch(error => console.log(error))
}

function playVideoStream(video, stream) {
  video.onloadedmetadata = () => video.play()

  if ("srcObject" in video) {
    video.srcObject = stream
  } else {
    // Avoid using this in new browsers, as it is going away.
    video.src = window.URL.createObjectURL(stream)
  }

  setTimeout(() => video.play(), 2000) // Safari on iPhone
}

let previewStream = null

function updatePreview() {
  let previewVideo = document.getElementById("previewVideo")
  if (previewVideo == null) {
    if (previewStream != null) {
      stopVideoStream(previewStream)
      previewStream = null
    }
    return
  }
  if (previewStream != null) return

  getUserMedia(previewVideo, (stream) => previewStream = stream)
}

function onPhxUpdate() {
  updateChat()
  updatePreview()
}

document.addEventListener("phx:update", onPhxUpdate)