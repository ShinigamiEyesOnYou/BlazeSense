import UIKit

class DetectionBoxView: UIView {
    private let labelLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.backgroundColor = .systemBlue.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 3
        layer.cornerRadius = 6
        
        addSubview(labelLabel)
        
        NSLayoutConstraint.activate([
            labelLabel.topAnchor.constraint(equalTo: topAnchor, constant: -25),
            labelLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with detection: DetectedObject) {
        if detection.confidence > 0.7 {
            labelLabel.text = " \(detection.label) \(Int(detection.confidence * 100))% "
        } else {
            labelLabel.text = " \(detection.label) "
        }
        labelLabel.sizeToFit()
        
        if detection.confidence > 0.8 {
            layer.borderColor = UIColor.systemGreen.cgColor
            labelLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.7)
        } else if detection.confidence > 0.6 {
            layer.borderColor = UIColor.systemBlue.cgColor
            labelLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)
        } else {
            layer.borderColor = UIColor.systemOrange.cgColor
            labelLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.7)
        }
    }
} 