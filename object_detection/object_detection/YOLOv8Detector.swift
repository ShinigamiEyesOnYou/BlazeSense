import CoreML
import Vision
import UIKit

class YOLODetector {
    private var visionModel: VNCoreMLModel?
    private var requests = [VNCoreMLRequest]()
    private(set) var isInitialized = false
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        print("Searching for ML model in bundle...")
        
        // First try to load compiled model
        if let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodelc") {
            print("✅ Found compiled model at:", modelURL.path)
            do {
                let config = MLModelConfiguration()
                let coreMLModel = try MLModel(contentsOf: modelURL, configuration: config)
                visionModel = try VNCoreMLModel(for: coreMLModel)
                
                if let visionModel = visionModel {
                    let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                        self?.processDetections(for: request, error: error)
                    }
                    request.imageCropAndScaleOption = .scaleFit
                    requests = [request]
                    isInitialized = true
                    print("✅ Model initialized successfully")
                    return
                }
            } catch {
                print("❌ Failed to load compiled model:", error.localizedDescription)
            }
        }
        
        // If compiled model fails, try uncompiled model
        if let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodel") {
            print("Found uncompiled model at:", modelURL.path)
            do {
                let config = MLModelConfiguration()
                let coreMLModel = try MLModel(contentsOf: modelURL, configuration: config)
                visionModel = try VNCoreMLModel(for: coreMLModel)
                
                if let visionModel = visionModel {
                    let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                        self?.processDetections(for: request, error: error)
                    }
                    request.imageCropAndScaleOption = .scaleFit
                    requests = [request]
                    isInitialized = true
                    print("✅ Model initialized successfully")
                    return
                }
            } catch {
                print("❌ Failed to create model:", error.localizedDescription)
            }
        }
        
        // If both attempts fail, print debug info
        print("❌ Failed to find model in bundle")
        if let bundlePath = Bundle.main.resourcePath {
            print("Bundle resource path:", bundlePath)
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: bundlePath) {
                print("Files in bundle:", files)
            }
        }
    }
    
    private var detectionCallback: (([DetectedObject]) -> Void)?
    
    func detect(in image: CVPixelBuffer, callback: @escaping ([DetectedObject]) -> Void) {
        detectionCallback = callback
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .up)
        do {
            try handler.perform(requests)
        } catch {
            print("Failed to perform detection: \(error.localizedDescription)")
        }
    }
    
    private func processDetections(for request: VNRequest, error: Error?) {
        if let error = error {
            print("Detection error: \(error.localizedDescription)")
            return
        }
        
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            print("Unexpected result type from VNCoreMLRequest")
            return
        }
        
        let detectedObjects = observations
            .filter { $0.confidence > 0.5 }
            .map { observation -> DetectedObject in
                let bbox = observation.boundingBox
                let label = observation.labels.first?.identifier ?? "Unknown"
                let confidence = observation.confidence
                
                return DetectedObject(
                    label: label,
                    confidence: confidence,
                    boundingBox: bbox
                )
            }
        
        DispatchQueue.main.async { [weak self] in
            self?.detectionCallback?(detectedObjects)
        }
    }
}

struct DetectedObject {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
} 
