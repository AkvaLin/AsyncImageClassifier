//
//  main.swift
//  ImageClassifierAsync
//
//  Created by Никита Пивоваров on 26.02.2024.
//

import Foundation
import CoreML

final class AsyncController {
    let imageClassifier = ImageClassifier()
    
    // MARK: - In/Out
    
    let inputQueue = DispatchQueue(label: "Input")
    let outputQueue = DispatchQueue(label: "Output", attributes: .concurrent)
    
    // MARK: - Data Queue
    let dataQueues = [
        DispatchQueue(label: "First Data", attributes: .concurrent),
        DispatchQueue(label: "Second Data", attributes: .concurrent),
        DispatchQueue(label: "Third Data", attributes: .concurrent)
    ]
    // MARK: - Data
    
    private var urls: [URL] = []
    
    // MARK: - Methods
    
    private func getUrls() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Images.bundle") else { return }
        self.urls = urls
    }
    
    private func getInputs(urls: [URL], clouser: @escaping ([(url: URL, input: MyImageClassifier_2Input)]) -> Void) {
        inputQueue.sync {
            var inputs = [(URL, MyImageClassifier_2Input)]()
            
            urls.forEach { url in
                guard let input = try? MyImageClassifier_2Input(imageAt: url) else { return }
                inputs.append((url, input))
            }
            
            clouser(inputs)
        }
    }
    
    private func write(result: [String: String]) {
        outputQueue.async(flags: .barrier) {
            
            let filename = self.getDocumentsDirectory().appendingPathComponent("output.json")
            var resultDict = result
            if
                let oldData = try? Data(contentsOf: filename),
                var oldJSON = try? JSONSerialization.jsonObject(with: oldData) as? [String: String]
            {
                result.forEach { (key, value) in oldJSON[key] = value }
                resultDict = oldJSON
            }
            
            do {
                try JSONSerialization.data(withJSONObject: resultDict, options: .prettyPrinted).write(to: filename, options: .atomic)
            } catch { }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func classification(queue: DispatchQueue, mainGroup: DispatchGroup, inputs: [(url: URL, input: MyImageClassifier_2Input)]) {
        mainGroup.enter()
        var result = [String: String]()
        let group = DispatchGroup()
        
        group.enter()
        queue.async {
            inputs.forEach { (url, input) in
                self.imageClassifier.predict(input: input) { prediction in
                    result[url.lastPathComponent] = prediction
                    if result.count == inputs.count {
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: outputQueue) {
            self.write(result: result)
            mainGroup.leave()
        }
    }
    
    public func getNUrls(amount: Int = 5) -> [URL]? {
        if urls.count == 0 {
            return nil
        }
        
        if urls.count > amount {
            let urls = Array(self.urls[0..<amount])
            self.urls.removeFirst(amount)
            return urls
        } else {
            let urls = self.urls
            self.urls = []
            return urls
        }
    }
    
    private func startQueue(queue: DispatchQueue) {
        if let urls = getNUrls() {
            let group = DispatchGroup()
            
            getInputs(urls: urls) { [weak self] data in
                self?.classification(queue: queue, mainGroup: group, inputs: data)
            }
            
            group.notify(queue: .global()) { [weak self] in
                guard let self = self else { return }
                startQueue(queue: queue)
            }
        }
    }
    
    public func getResult() {
        getUrls()
        print(urls[0])
        dataQueues.forEach { queue in
            startQueue(queue: queue)
        }
    }
    
    public func rename() {
        getUrls()
        
        urls.forEach { url in
            var newUrl = url.deletingLastPathComponent().appendingPathComponent("IMG_\(UUID())", conformingTo: .jpeg)
            do {
                try FileManager.default.moveItem(at: url, to: newUrl)
            } catch {
                print(error)
            }
            
        }
    }
}
