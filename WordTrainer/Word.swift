//
//  Word.swift
//  WordTrainer
//
//  Created by Cyril Wendl on 23.01.2026.
//

import Foundation
import SwiftData

@Model
final class Word: Identifiable, Codable {
    @Attribute(.unique) var id: UUID = UUID()
    var native: String
    var foreign: String
    var score: Int
    var createdAt: Date
    var lastCorrectAt: Date?
    // Make mastered mutable so Edit/Practice can update it
    var mastered: Bool

    init(native: String, foreign: String, score: Int = 0, createdAt: Date = Date(), lastCorrectAt: Date? = nil, mastered: Bool? = nil) {
        self.native = native
        self.foreign = foreign
        self.score = score
        self.createdAt = createdAt
        self.lastCorrectAt = lastCorrectAt
        self.mastered = mastered ?? (score >= 5)
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, native, foreign, score, createdAt, lastCorrectAt, mastered
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let native = try container.decode(String.self, forKey: .native)
        let foreign = try container.decode(String.self, forKey: .foreign)
        let score = try container.decode(Int.self, forKey: .score)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let lastCorrectAt = try container.decodeIfPresent(Date.self, forKey: .lastCorrectAt)
        let mastered = try container.decodeIfPresent(Bool.self, forKey: .mastered)
        self.init(native: native, foreign: foreign, score: score, createdAt: createdAt, lastCorrectAt: lastCorrectAt, mastered: mastered)
        self.id = id
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(native, forKey: .native)
        try container.encode(foreign, forKey: .foreign)
        try container.encode(score, forKey: .score)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastCorrectAt, forKey: .lastCorrectAt)
        try container.encode(mastered, forKey: .mastered)
    }
}
