//
//  ViewController.swift
//  object_detection
//
//  Created by Fettah elcik on 29.12.2024.
//

import UIKit
import AVFoundation
import FirebaseAuth

@available(iOS 15.0, *)
class ViewController: UIViewController {
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var detector: YOLODetector!
    private var detectionBoxes: [DetectionBoxView] = []
    
    private let buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let button1: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Button 1", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let button2: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Button 2", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let button3: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Button 3", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let cameraContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupNavigationBar()
        setupUI()
        
        // Initialize detector first
        detector = YOLODetector()
        if !detector.isInitialized {
            showError("Failed to initialize object detector")
        }
        
        // Then setup camera
        checkCameraPermissions()
    }
    
    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true // Hide back button
        
        // Create a bold logout button
        let logoutButton = UIBarButtonItem(
            title: "Logout",
            style: .done,
            target: self,
            action: #selector(logoutButtonTapped)
        )
        
        // Make it more visible
        logoutButton.tintColor = .red
        logoutButton.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ], for: .normal)
        
        // Set as right bar button
        navigationItem.rightBarButtonItem = logoutButton
        
        title = "Camera"
    }
    
    @objc private func backButtonTapped() {
        // Show alert that logout is required
        let alert = UIAlertController(
            title: "Logout Required",
            message: "Please use the logout button to exit",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func logoutButtonTapped() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            do {
                try Auth.auth().signOut()
                // Return to login screen
                self?.navigationController?.popToRootViewController(animated: true)
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        })
        
        present(alert, animated: true)
    }
    
    private func setupButtons() {
        view.addSubview(buttonsStackView)
        
        buttonsStackView.addArrangedSubview(button1)
        buttonsStackView.addArrangedSubview(button2)
        buttonsStackView.addArrangedSubview(button3)
        
        NSLayoutConstraint.activate([
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            showCameraAccessAlert()
        }
    }
    
    private func showCameraAccessAlert() {
        showError("Camera access required")
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to use this feature",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func setupUI() {
        // Add background image
        let backgroundImageView = UIImageView(image: UIImage(named: "blazeSense_login"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        // Add semi-transparent overlay
        let overlayView = UIView()
        overlayView.backgroundColor = .black.withAlphaComponent(0.6)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        // Add camera container and buttons
        view.addSubview(cameraContainerView)
        view.addSubview(buttonsStackView)
        
        // Add buttons to stack view
        buttonsStackView.addArrangedSubview(button1)
        buttonsStackView.addArrangedSubview(button2)
        buttonsStackView.addArrangedSubview(button3)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Background constraints
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Overlay constraints
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Camera container constraints
            cameraContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cameraContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            
            // Buttons stack view constraints
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        // Begin configuration
        captureSession.beginConfiguration()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { 
            showError("Camera device not available")
            captureSession.commitConfiguration()
            return 
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                showError("Failed to initialize camera")
                captureSession.commitConfiguration()
                return
            }
            
            // Setup video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            // Commit configuration before creating preview layer
            captureSession.commitConfiguration()
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = cameraContainerView.bounds
            previewLayer.videoGravity = .resizeAspectFill
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.cameraContainerView.layer.addSublayer(self.previewLayer)
                self.errorLabel.isHidden = true
                
                // Start running after everything is set up
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                }
            }
            
        } catch {
            captureSession.commitConfiguration()
            showError("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = previewLayer {
            previewLayer.frame = cameraContainerView.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
            print("Failed to get pixel buffer from sample buffer")
            return 
        }
        
        // Check if detector is initialized
        guard let detector = detector else {
            print("Detector is not initialized")
            return
        }
        
        detector.detect(in: pixelBuffer) { [weak self] detections in
            self?.updateDetectionBoxes(with: detections)
        }
    }
    
    private func updateDetectionBoxes(with detections: [DetectedObject]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove old detection boxes
            self.detectionBoxes.forEach { $0.removeFromSuperview() }
            self.detectionBoxes.removeAll()
            
            // Create new detection boxes
            for detection in detections {
                // Only show detections with confidence > 0.5 (50%)
                guard detection.confidence > 0.5 else { continue }
                
                let boxView = DetectionBoxView(frame: .zero)
                boxView.configure(with: detection)
                
                // Convert normalized coordinates to view coordinates
                let viewWidth = self.cameraContainerView.bounds.width
                let viewHeight = self.cameraContainerView.bounds.height
                
                let x = detection.boundingBox.minX * viewWidth
                let y = detection.boundingBox.minY * viewHeight
                let width = detection.boundingBox.width * viewWidth
                let height = detection.boundingBox.height * viewHeight
                
                boxView.frame = CGRect(x: x, y: y, width: width, height: height)
                self.cameraContainerView.addSubview(boxView)
                self.detectionBoxes.append(boxView)
            }
        }
    }
}

