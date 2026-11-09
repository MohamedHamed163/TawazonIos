//
//  AppTextField.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct AppTextField: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil
    var isRequired: Bool = false
    
    @State private var isPasswordVisible = false
    @FocusState private var isFocused: Bool
    
    private func getFocusedBorderColor() -> Color {
        return themeManager.dynamicColorTheme.currentPrimary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack(spacing: 4) {
                Text(title)
                    .textStyle(Typography.Style.subheadlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                if isRequired {
                    Text("*")
                        .foregroundColor(ColorTheme.Semantic.error)
                }
            }
            
            // Input Field
            HStack {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .font(.body)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.body)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .focused($isFocused)
                }
                
                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding()
            .background(themeManager.isDarkMode ? ColorTheme.Input.background : ColorTheme.Input.backgroundLight)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? getFocusedBorderColor() : (themeManager.isDarkMode ? ColorTheme.Input.border : ColorTheme.Input.borderLight), lineWidth: isFocused ? 2 : 1)
            )
            .cornerRadius(12)
            
            // Error Message
            if let error = errorMessage {
                Text(error)
                    .textStyle(Typography.Style.caption, color: ColorTheme.Semantic.error)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppTextField(
            title: "Email",
            text: .constant(""),
            placeholder: "Enter your email",
            keyboardType: .emailAddress,
            isRequired: true
        )
        
        AppTextField(
            title: "Password",
            text: .constant(""),
            placeholder: "Enter your password",
            isSecure: true,
            isRequired: true
        )
        
        AppTextField(
            title: "Full Name",
            text: .constant(""),
            placeholder: "Enter your full name",
            errorMessage: "This field is required"
        )
    }
    .padding()
    .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: ThemeManager().isDarkMode))
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}

