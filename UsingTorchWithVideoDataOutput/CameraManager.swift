import AVFoundation
import Combine
import CoreImage

protocol CameraManagerDelegate {
  func processImage(ciImage: CIImage)
}

class CameraManager: NSObject {
  private(set) var captureSession = AVCaptureSession()
  var delegate: CameraManagerDelegate? = nil

  private let photoOutput = AVCapturePhotoOutput()
  private let videoDataOutput = AVCaptureVideoDataOutput()
  private let videoQueue = DispatchQueue(
    label: "com.example.UseTorchWithVideoDataOutput.VideoQueue", qos: .userInteractive)

  private var lastCapturedTime = CFAbsoluteTimeGetCurrent()

  enum ConfigurationError: Error {
    case cameraUnavailable
    case inputUnavailable
    case photoOutputUnavailable
    case videoDataOutputUnavailable
  }

  override init() {
    super.init()

    do {
      try setup()
    } catch {
      fatalError("Failed to setup CameraManager: \(error)")
    }
  }
  private func setup() throws {
    // self.captureSession.sessionPreset = .inputPriority
    self.captureSession.beginConfiguration()

    guard
      let videoDevice = AVCaptureDevice.default(
        .builtInWideAngleCamera, for: .video, position: .back)
    else {
      throw ConfigurationError.cameraUnavailable
    }

    let videoInput = try AVCaptureDeviceInput(device: videoDevice)

    if self.captureSession.canAddInput(videoInput) {
      self.captureSession.addInput(videoInput)
    } else {
      throw ConfigurationError.inputUnavailable
    }
    if self.captureSession.canAddOutput(self.photoOutput) {
      self.captureSession.addOutput(self.photoOutput)
    } else {
      throw ConfigurationError.photoOutputUnavailable
    }
    if self.captureSession.canAddOutput(self.videoDataOutput) {
      self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
      self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
      self.captureSession.addOutput(self.videoDataOutput)
    } else {
      throw ConfigurationError.videoDataOutputUnavailable
    }

    self.captureSession.commitConfiguration()
  }
  func start() {
    self.captureSession.startRunning()
  }
  func stop() {
    self.captureSession.stopRunning()
  }
  func toggleTorch() -> Bool {
    guard
      let videoDevice = AVCaptureDevice.default(
        .builtInWideAngleCamera, for: .video, position: .back)
    else {
      return false
    }
    do {
      try videoDevice.lockForConfiguration()

      if videoDevice.torchMode == .off {
        try videoDevice.setTorchModeOn(level: 1.0)
      } else {
        videoDevice.torchMode = .off
      }

      videoDevice.unlockForConfiguration()
    } catch {
      return false
    }

    return videoDevice.torchMode == .on
  }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    let capturedTime = CFAbsoluteTimeGetCurrent()
    let duration = capturedTime - self.lastCapturedTime

    if duration < 1.0 {
      return
    }

    self.lastCapturedTime = capturedTime

    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
      .oriented(.right)

    guard let delegate = self.delegate else {
      return
    }

    delegate.processImage(ciImage: ciImage)
  }
}
