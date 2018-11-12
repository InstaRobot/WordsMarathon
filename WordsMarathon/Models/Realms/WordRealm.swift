//
//  WordRealm.swift
//  WordsMarathon
//
//  Created by Vitaliy Podolskiy on 12/11/2018.
//  Copyright © 2018 Vitaliy Podolskiy. All rights reserved.
//

import Foundation
import RealmSwift

class WordRealm: Object {

	@objc dynamic var _id = ""

  override static func indexedProperties() -> [String] {
    return ["_id"]
  }

  override static func primaryKey() -> String? {
    return "_id"
  }
    
	override static func ignoredProperties() -> [String] {
	  return []
	}



}
