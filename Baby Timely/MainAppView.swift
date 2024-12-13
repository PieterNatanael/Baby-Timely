//
//  MainAppView.swift
//  Time Tell
//
//  Created by Pieter Yoshua Natanael on 04/12/24.
//


import SwiftUI
import CoreLocation

struct MainAppView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Image(systemName: "pills.fill")
                    Text("Take Medication")
                }
                .tag(0)
            
           NotesView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Notes")
                }
                .tag(1)
            
//            DiaryView(dataStore: DataStore())
//                .tabItem {
//                    Image(systemName: "square.and.pencil")
//                    Text("Diary")
//                }
//                .tag(2)
        }
    }
}
