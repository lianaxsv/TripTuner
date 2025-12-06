//
//  StorageHelper.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseAuth

class StorageHelper {
    static let shared = StorageHelper()
    private let storage = Storage.storage()
    
    private init() {}
    
    // Upload a single image and return its download URL
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "StorageHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "StorageHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    // Upload multiple images and return their download URLs
    func uploadImages(_ images: [UIImage], basePath: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let group = DispatchGroup()
        var urls: [String] = []
        var uploadError: Error?
        
        for image in images {
            group.enter()
            let path = "\(basePath)/\(UUID().uuidString).jpg"
            
            uploadImage(image, path: path) { result in
                switch result {
                case .success(let url):
                    urls.append(url)
                case .failure(let error):
                    uploadError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
            } else {
                completion(.success(urls))
            }
        }
    }
    
    // Upload profile picture
    func uploadProfilePicture(_ image: UIImage, userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Upload without .jpg extension to match Firebase Storage rules pattern
        let path = "profile_pictures/\(userID)"
        uploadImage(image, path: path, completion: completion)
    }
}

