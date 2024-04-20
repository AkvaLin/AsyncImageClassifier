//
//  ImageClassifier.swift
//  ImageClassifierAsync
//
//  Created by Никита Пивоваров on 04.03.2024.
//

import Foundation
import CoreML

final class ImageClassifier {
    let classifier = try? MyImageClassifier_2()
    
    public func predict(input: MyImageClassifier_2Input, clouser: @escaping (String?) -> Void) {
        guard let classifier = classifier else { clouser(nil); return }
        
        Task {
            let prediction = try? await classifier.prediction(input: input)
            clouser(prediction?.target)
        }
    }
}
