import Combine
import CoreImage
import Vision

class ImageClassifier {
  struct Prediction: Identifiable {
    let id = UUID()

    let classification: String
    let confidence: Float
  }

  var result: AnyPublisher<[Prediction], Never> {
    self.resultSubject.eraseToAnyPublisher()
  }

  private let resultSubject = PassthroughSubject<[Prediction], Never>()

  private var model: VNCoreMLModel

  init() {
    do {
      let defaultConfig = MLModelConfiguration()
      let imageClassifier = try MobileNetV2FP16(configuration: defaultConfig)
      let imageClassifierVisionModel = try VNCoreMLModel(for: imageClassifier.model)

      self.model = imageClassifierVisionModel
    } catch {
      fatalError("Failed to setup ImageClassifier: \(error)")
    }
  }
  private func createImageClassificationRequest() -> VNImageBasedRequest {
    let request = VNCoreMLRequest(
      model: self.model,
      completionHandler: self.visionRequestHandler)

    request.imageCropAndScaleOption = .centerCrop

    return request
  }
  private func visionRequestHandler(_ request: VNRequest, error: Error?) {
    var predictions: [Prediction] = []

    defer {
      DispatchQueue.main.async {
        self.resultSubject.send(predictions)
      }
    }

    if let error = error {
      print("Cannot process request: \(error)")
      return
    }
    if request.results == nil {
      print("No results.")
      return
    }
    guard let observations = request.results as? [VNClassificationObservation] else {
      print("VNRequest produced the wrong result type.")
      return
    }

    predictions = observations.map { observation in
      Prediction(
        classification: observation.identifier,
        confidence: observation.confidence)
    }
  }
  func makePredictions(for ciImage: CIImage) throws {
    let request = self.createImageClassificationRequest()
    let requests: [VNRequest] = [request]
    let handler = VNImageRequestHandler(ciImage: ciImage)

    try handler.perform(requests)
  }
}

extension ImageClassifier: CameraManagerDelegate {
  func processImage(ciImage: CIImage) {
    /*@@@begin
    guard let squareImage = ciImage.square() else {
      return
    }
    guard let smallImage = squareImage.resize(targetSize: CGSize(width: 299, height: 299)) else {
      return
    }
@@@end*/
    do {
      try self.makePredictions(for: ciImage)
    } catch {
      fatalError("failed to make prediction: \(error)")
    }
  }
}
