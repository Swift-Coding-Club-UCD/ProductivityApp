//
//  LoginView.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 1/26/26.
//

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var wrongUsername = 0
    @State private var wrongPassword = 0
    @State private var showingLoginScreen = false
    var body: some View {
        NavigationView {
                    VStack {
                        Text("Login")
                            .font(.largeTitle)
                            .bold()
                            .padding()
                        TextField("Username", text: $username)
                            .padding()
                            .frame(width:300, height:50)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(10)
                            .border(.red, width: CGFloat(wrongUsername))
                        SecureField("Password", text: $password)
                            .padding()
                            .frame(width:300, height:50)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(10)
                            .border(.red, width: CGFloat(wrongPassword))
                        Button("Login") {
                            //authenticate user
                        }
                        .foregroundColor(.white)
                        .frame(width: 300, height:50)
                        .background(Color.blue)
                        .cornerRadius(10)
                        
                        //NavigationLink(destination: Text("You are logged in @\(username)"), isActive: $showingLoginScreen) {
                          //  EmptyView()
                        //}
                    }
                } .navigationBarHidden(true)
        
    }
}

#Preview {
    LoginView()
}
