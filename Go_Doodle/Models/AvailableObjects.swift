//
//  AvailableObjects.swift
//  Go_Doodle
//
//  Created by Oleksandr Kataskin on 24.06.2025.
//

import Foundation

enum AvailableObjects: String, CaseIterable {
    case shark, bird, turtle
    
    static func random() -> AvailableObjects {
        return AvailableObjects.allCases.randomElement() ?? .shark
    }
}
