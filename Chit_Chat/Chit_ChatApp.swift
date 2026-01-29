//
//  Chit_ChatApp.swift
//  Chit_Chat
//
//  Created by Satyam Sharma Chingari on 29/01/26.
//

import SwiftUI

@main
struct Chit_ChatApp: App {
    init() {
        AudioSessionConfigurator.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

