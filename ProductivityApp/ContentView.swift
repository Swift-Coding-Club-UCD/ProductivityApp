import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Your Task Branch content likely belongs here
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ViewB()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
            
            ViewC()
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Settings")
                }
        }
    }
}

// This represents the code from your Task Branch


#Preview {ContentView()}
