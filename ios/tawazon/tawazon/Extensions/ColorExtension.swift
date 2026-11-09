//
//  ColorExtension.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

extension Color {
    // Legacy support - these are now defined in ColorTheme.swift
    // Keeping this file for any additional color extensions if needed
    static var appSecondary: Color { ColorTheme.Background.primary }
    static var appAccent: Color { ColorTheme.primary }
}

