# Using Torch with Video Data Output

This is a sample app that uses AVCaptureVideoDataOutput to process images frame by frame with the torch turned on.

## System Requirements

- iOS 15.0+
- Xcode 14.2+

## Usage

When you launch the app, the camera preview will be displayed. At the bottom of the screen, the button to turn the torch on and off will be displayed. Below that, you'll see the results of image classification using the MobileNetV2 machine learning model.

Image classification is performed approximately every second. Try testing in a dark environment to see how the classification results change with and without the torch.

## Implementation Details

Normally, you cannot turn on the torch during photo or video preview. This behavior is also applied standard iOS camera app.

However, I don't know why but you add AVCapturePhotoOutput to AVCaptureSession, the torch will be able to turn on. Testing on actual iPhone devices, I've see the torch functioned as expected at least from iOS 15 to iOS 17.

Additionally, even if you remove AVCaptureSessionPhotoOutput, the preview function will still work. However, if you implement it this way, calling the `.setTorchModeOn(level: Float)` method will succeed, but the torch will not turn on.

## License

MIT
