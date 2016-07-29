//
//  Post.swift
//  Timeline
//
//  Created by Natalie Lim on 7/28/16.
//  Copyright © 2016 Dianatalie. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit


class Post: SyncableObject, SearchableRecord, CloudKitManagedObject {
    
    static let typeKey = "Post"
    static let photoDataKey = "photoData"
    static let timestampKey = "timestamp"
    
    convenience init(photo: NSData, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let entity = NSEntityDescription.entityForName(Post.typeKey, inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = photo
        self.timestamp = timestamp
        self.recordName = self.nameForManagedObject()
    }
    
    var photo: UIImage? {
        
        guard let photoData = self.photoData else { return nil }
        
        return UIImage(data: photoData)
    }
    
    lazy var temporaryPhotoURL: NSURL = {
        
        // Must write to temporary directory to be able to pass image file path url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(self.recordName).URLByAppendingPathExtension("jpg")
        
        self.photoData?.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
    
    // MARK: - SearchableRecord
    
    func matchesSearchTerm(searchTerm: String) -> Bool {
        
        return (self.comments?.array as? [Comment])?.filter({ $0.matchesSearchTerm(searchTerm) }).count > 0
    }
    
    // MARK: - CloudKitManagedObject
    
    var recordType: String = Post.typeKey
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Post.timestampKey] = timestamp
        record[Post.photoDataKey] = CKAsset(fileURL: temporaryPhotoURL)
        
        return record
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let timestamp = record.creationDate,
            let photoData = record[Post.photoDataKey] as? CKAsset else { return nil }
        
        guard let entity = NSEntityDescription.entityForName(Post.typeKey, inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        self.timestamp = timestamp
        self.photoData = NSData(contentsOfURL: photoData.fileURL)
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        self.recordName = record.recordID.recordName
    }
}