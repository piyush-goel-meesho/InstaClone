//
//  LoginViewModel.swift
//  InstaClone
//
//  Created by Piyush Goel on 22/12/25.
//

import Foundation
internal import Combine

// ============================================================================
// Login View Model
// ============================================================================

// ViewModel responsible for handling login state and validation logic
class LoginViewModel: ObservableObject {

    // User input fields
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var isLoggedIn = false
    @Published var errorMessage: String? = nil

    init() {
        checkLoginState()
    }

    func checkLoginState() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    // Validates whether the login form can be submitted
    var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private var validEmail = "user@example.com"
    private var validPassword = "password123"

    func login() {

        if email == validEmail && password == validPassword {

            // Persist login state
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(email, forKey: "userEmail")

            // Update UI state
            isLoggedIn = true
            errorMessage = nil

        } else {
            // Show error message on failure
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            
            isLoggedIn = false
            errorMessage = "Invalid Credentials"
        }
    }

    func logout() {

        // Reset local state
        email = ""
        password = ""
        isLoggedIn = false
        errorMessage = nil

        // Clear persisted login data
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}
