//
//  CoreDataManager.swift
//  InstaClone
//
//  Created by Piyush Goel on 23/12/25.
//

import Foundation
import CoreData
import UIKit

// ============================================================================
// CoreDataManager
// ---------------------------------------------------------------------------
// Centralized Core Data helper responsible for:
// - Saving & fetching Posts
// - Saving & fetching Reels
// - Updating likes
// - Clearing cached data
// ============================================================================

class CoreDataManager {

    static let shared = CoreDataManager()

    // Reference to PersistenceController
    private let persistenceController = PersistenceController.shared

    // Main view context used for all Core Data operations
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    // Private initializer to enforce singleton usage
    private init() {}

    // Image Operations

    func saveImages(_ imageURL: String) {
        guard let url = URL(string: imageURL) else {return}
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                    return
                }

                Task {
                    await context.perform {
                        let imageEntity = ImageEntity(context: self.context)
                        imageEntity.image = data
                        imageEntity.url = imageURL
                        self.saveContext()
                    }
                }
                
                print("Image saved in cache : \(type(of: UIImage(data: data)!))")
            } catch {
                print("Error saving image")
            }
        }
    }

    func fetchImage(_ imageURL: String) -> UIImage? {
        let request: NSFetchRequest<ImageEntity> = ImageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", imageURL)
        do {
            let imageEntities = try context.fetch(request)
            if let validImage = imageEntities.first?.uiImage {
                print("Valid image found : \(type(of: validImage))")
                return validImage
            } else {
                print("No valid image found")
                return UIImage()
            }
        } catch {
            print("Error fetching image")
            return nil
        }
    }

    // =========================================================================
    // Posts Operations
    // =========================================================================

    // Save posts to Core Data (clears cache first)
    func savePosts(_ posts: [Post]) {
        context.perform {
            // Remove old cached posts (inline to avoid nested context.perform)
            self.clearAllPostsSync()

            // Insert new posts
            for post in posts {
                let postEntity = PostEntity(context: self.context)
                postEntity.id = post.id
                postEntity.userName = post.userName
                postEntity.userImage = post.userImage
                postEntity.postImage = post.postImage
                postEntity.likeCount = Int32(post.likeCount)
                postEntity.likedByUser = post.likedByUser
            }

            self.saveContext()
        }
        
        for post in posts {
            saveImages(post.postImage)
            saveImages(post.userImage)
        }
    }

    // Fetch all cached posts from Core Data
    func fetchPosts() -> [Post] {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()

        // Sort posts deterministically
        request.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]

        do {
            let postEntities = try context.fetch(request)

            // Convert Core Data entities to domain models
            return postEntities.map { entity in
                Post(
                    id: entity.id ?? "",
                    userName: entity.userName ?? "",
                    userImage: entity.userImage ?? "",
                    postImage: entity.postImage ?? "",
                    likeCount: Int(entity.likeCount),
                    likedByUser: entity.likedByUser
                )
            }
        } catch {
            print("Error fetching posts: \(error)")
            return []
        }
    }

    // Update a single post (used mainly for like toggles)
    func updatePost(_ post: Post) {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", post.id)

        do {
            let results = try context.fetch(request)
            if let postEntity = results.first {
                postEntity.userName = post.userName
                postEntity.userImage = post.userImage
                postEntity.postImage = post.postImage
                postEntity.likeCount = Int32(post.likeCount)
                postEntity.likedByUser = post.likedByUser

                self.saveContext()
            }
        } catch {
            print("Error updating post: \(error)")
        }
    }

    // Remove all cached posts using batch delete (public version)
    func clearAllPosts() {
        context.perform {
            self.clearAllPostsSync()
        }
    }

    // Remove all cached posts - synchronous version for internal use
    private func clearAllPostsSync() {
        let request: NSFetchRequest<NSFetchRequestResult> = PostEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            // Refresh context after batch delete
            context.refreshAllObjects()
            self.saveContext()
        } catch {
            print("Error clearing posts: \(error)")
        }
    }

    // =========================================================================
    // Reels Operations
    // =========================================================================

    // Save reels to Core Data (clears existing cache first)
    func saveReels(_ reels: [Reel]) {
        context.perform {
            // Remove old cached reels (inline to avoid nested context.perform)
            self.clearAllReelsSync()

            // Insert new reels
            for reel in reels {
                let reelEntity = ReelEntity(context: self.context)
                reelEntity.id = reel.id
                reelEntity.userName = reel.userName
                reelEntity.userImage = reel.userImage
                reelEntity.reelVideo = reel.reelVideo
                reelEntity.likeCount = Int32(reel.likeCount)
                reelEntity.likedByUser = reel.likedByUser
            }

            // Persist changes
            self.saveContext()
        }
    }

    // Fetch all cached reels from Core Data
    func fetchReels() -> [Reel] {
        let request: NSFetchRequest<ReelEntity> = ReelEntity.fetchRequest()

        // Sort reels deterministically
        request.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]

        do {
            let reelEntities = try context.fetch(request)

            // Convert Core Data entities to domain models
            return reelEntities.map { entity in
                Reel(
                    id: entity.id ?? "",
                    userName: entity.userName ?? "",
                    userImage: entity.userImage ?? "",
                    reelVideo: entity.reelVideo ?? "",
                    likeCount: Int(entity.likeCount),
                    likedByUser: entity.likedByUser
                )
            }
        } catch {
            print("Error fetching reels: \(error)")
            return []
        }
    }

    // Update a single reel (used mainly for like toggles)
    func updateReel(_ reel: Reel) {
        let request: NSFetchRequest<ReelEntity> = ReelEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reel.id)

        do {
            let results = try context.fetch(request)
            if let reelEntity = results.first {
                reelEntity.userName = reel.userName
                reelEntity.userImage = reel.userImage
                reelEntity.reelVideo = reel.reelVideo
                reelEntity.likeCount = Int32(reel.likeCount)
                reelEntity.likedByUser = reel.likedByUser

                self.saveContext()
            }
        } catch {
            print("Error updating reel: \(error)")
        }
    }

    // Remove all cached reels using batch delete (public version)
    func clearAllReels() {
        context.perform {
            self.clearAllReelsSync()
        }
    }

    // Remove all cached reels - synchronous version for internal use
    private func clearAllReelsSync() {
        let request: NSFetchRequest<NSFetchRequestResult> = ReelEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            // Refresh context after batch delete
            context.refreshAllObjects()
            self.saveContext()
        } catch {
            print("Error clearing reels: \(error)")
        }
    }

    // =========================================================================
    // Context Saving
    // =========================================================================

    // Persist Core Data context changes safely
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
