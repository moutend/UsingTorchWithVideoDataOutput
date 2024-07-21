import SwiftUI

struct ContentView: View {
  private let imageClassifier = ImageClassifier()
  private let cameraManager = CameraManager()

  @State private var predictions: [ImageClassifier.Prediction] = []
  @State private var torch = false

  var body: some View {
    VStack {
      PreviewView(captureSession: self.cameraManager.captureSession)
        .frame(width: UIScreen.main.bounds.size.width)
      Button(action: {
        self.torch = self.cameraManager.toggleTorch()
      }) {
        Text(self.torch ? "Disable Torch" : "Enable Torch")
          .padding()
          .foregroundColor(.white)
          .background(.indigo)
      }
      .padding()
      Text("Predictions")
        .font(.title)
        .bold()
      if let prediction = self.predictions.first {
        Text(
          "\(prediction.classification) - \(prediction.confidence * 100.0, specifier: "%.0f")%"
        )
        .padding()
      }
    }
    .onAppear {
      self.cameraManager.delegate = self.imageClassifier
      self.cameraManager.start()
    }
    .onDisappear {
      self.cameraManager.delegate = nil
      self.cameraManager.stop()
    }
    .onReceive(self.imageClassifier.result) { predictions in
      self.predictions = [ImageClassifier.Prediction](predictions.prefix(3))
    }
  }
}
