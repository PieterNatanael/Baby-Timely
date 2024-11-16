//
//  ContentView.swift
//  Baby Timely
//
//  Created by Pieter Yoshua Natanael on 26/10/24.
//




import SwiftUI
import StoreKit
import UserNotifications
import Combine


// ContentView
struct ContentView: View {
    @State private var showAdsAndAppFunctionality = false
    @State private var buttonStates = Array(repeating: false, count: 24) // Track button states for each hour
    @StateObject private var purchaseManager = PurchaseManager() // Purchase manager

    var body: some View {
        ZStack {
            
            // Background Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)),.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAdsAndAppFunctionality = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.white))
                                .padding()
                                .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                        }
                    }
                    // Purchase button for unlocking full version
               
                
                    
                    
                    Text("Baby Timely")                        .font(.title.bold())
                        .foregroundColor(.white)
                        .padding()
                    
                    // Grid of 24 buttons, representing 24 hours of the day
                    let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<24) { index in
                            Button(action: {
                                // Toggle button and handle notification scheduling/canceling
                                if buttonStates[index] {
                                    cancelNotification(for: index)
                                    buttonStates[index] = false
                                    saveButtonStates()
                                } else if buttonStates.filter({ $0 }).count < 3 || purchaseManager.unlimitedNotificationsUnlocked {
                                    buttonStates[index] = true
                                    scheduleNotification(for: index)
                                    saveButtonStates()
                                } else {
                                    print("Limit reached: Upgrade to unlock more notifications.")
                                }
                            }) {
                                Text("\(index):00")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(buttonStates[index] ? .white : .black)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        ZStack {
                                            // Gradient background
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    buttonStates[index] ? Color.green.opacity(0.9) : Color.white,
                                                    buttonStates[index] ? Color.green : Color.white.opacity(0.95)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            
                                            // Divider with softer appearance
                                            Rectangle()
                                                .fill(buttonStates[index] ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                                                .frame(width: 2, height: 50)
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(
                                                buttonStates[index] ? Color.white.opacity(0.3) : Color.gray.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: buttonStates[index] ? Color.green.opacity(0.4) : Color.gray.opacity(0.3),
                                        radius: 6,
                                        x: 0,
                                        y: 3
                                    )
                                    // Add subtle press animation
                                    .scaleEffect(buttonStates[index] ? 0.97 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonStates[index])
                            }
                        }
                    }
                    
                    VStack{
                        Button(action: {
                            if let product = purchaseManager.products.first {
                                purchaseManager.buyProduct(product)
                            }
                        }) {
                            Text("Unlimited Reminders")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(#colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)))
                                .foregroundColor(.white)
                                .font(.title3.bold())
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color.white.opacity(1), radius: 3, x: 3, y: 3)
                        }
                        
                        // Restore Purchases button
                        Button(action: {
                            purchaseManager.restorePurchases()
                        }) {
                            Text("Restore Purchases")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .font(.title3.bold())
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color(#colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)).opacity(12), radius: 3, x: 3, y: 3)
                        }
                        Spacer()
                    }
                    
                }
                .sheet(isPresented: $showAdsAndAppFunctionality) {
                    ShowAdsAndAppFunctionalityView(onConfirm: {
                        showAdsAndAppFunctionality = false
                    })
                }
//                .background(Color(.systemPink)) // Light pink background
                .onAppear {
                    loadButtonStates()
                    requestNotificationPermission()
                    purchaseManager.fetchProducts()
                }
                .padding()
            }
        }
    }

    // Save the button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }

    // Load the button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }

    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // Schedule a notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Baby Timely"
        content.body = "It's \(hour):00 – time to care for your baby!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "medication_\(hour)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification for \(hour):00 scheduled successfully.")
            }
        }
    }

    // Cancel a notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)"

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let remainingRequests = requests.filter { $0.identifier == identifier }
            if remainingRequests.isEmpty {
                print("Notification for \(hour):00 successfully canceled.")
            } else {
                print("Failed to cancel notification for \(hour):00.")
            }
        }
    }
}

// PurchaseManager class for handling in-app purchases
class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var unlimitedNotificationsUnlocked = false
    @Published var products: [SKProduct] = []
    
    private let productID = "com.baby.Unlimited" // Replace with your Product ID from App Store Connect
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Make sure to update on the main thread
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    // Restore previously made purchases
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // Ensure all updates are made on the main thread
                DispatchQueue.main.async {
                    self.unlimitedNotificationsUnlocked = true
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                if let error = transaction.error {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            default:
                break
            }
        }
    }
}

struct ShowAdsAndAppFunctionalityView: View {
    var onConfirm: () -> Void

    var body: some View {
        ScrollView {
            VStack {
                // Section header
                HStack {
                    Text("Ads & App Functionality")
                        .font(.title3.bold())
                    Spacer()
                }
                Divider().background(Color.gray)
                
                HStack {
                    Text("App Functionality")
                        .font(.title.bold())
                    Spacer()
                }

                Text("""
                • 24-Hour Selection: Choose the hour of the day to schedule reminders for your baby’s care. Free users can set up to 3 reminders.
                • Cancel Reminders: Easily cancel a scheduled reminder by pressing the corresponding hour button.
                • Unlimited Reminders: Purchase the Unlimited Reminders feature to set an unlimited number of reminders.
                •Restore Purchases: Restore your previously purchased Unlimited Reminders on any device, or if you reinstall the app on the same device.
                """)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .padding()

                // Ads section
                VStack {
                    // Ads header
                    HStack {
                        Text("App For You")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    // Ad image with link
               
                    
                    // App Cards for ads
                    VStack {
                        Divider().background(Color.gray)


                        AppCardView(imageName: "timetell", appName: "TimeTell", appDescription: "Announce the time every 30 seconds, no more guessing and checking your watch, for time-sensitive tasks.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "SingLoop", appName: "Sing LOOP", appDescription: "Record your voice effortlessly, and play it back in a loop.", appURL: "https://apps.apple.com/id/app/sing-l00p/id6480459464")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "loopspeak", appName: "LOOPSpeak", appDescription: "Type or paste your text, play in loop, and enjoy hands-free narration.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "insomnia", appName: "Insomnia Sheep", appDescription: "Design to ease your mind and help you relax leading up to sleep.", appURL: "https://apps.apple.com/id/app/insomnia-sheep/id6479727431")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "BST", appName: "Blink Screen Time", appDescription: "Using screens can reduce your blink rate to just 6 blinks per minute, leading to dry eyes and eye strain. Our app helps you maintain a healthy blink rate to prevent these issues and keep your eyes comfortable.", appURL: "https://apps.apple.com/id/app/blink-screen-time/id6587551095")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "iprogram", appName: "iProgramMe", appDescription: "Custom affirmations, schedule notifications, stay inspired daily.", appURL: "https://apps.apple.com/id/app/iprogramme/id6470770935")
                        Divider().background(Color.gray)

                       
                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(15.0)

                // App functionality section
      

                Spacer()

                HStack {
                    Text("Baby Timely is developed by Three Dollar.")
                        .font(.title3.bold())
                    Spacer()
                }

                // Close button
                Button("Close") {
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .font(.title3.bold())
                .cornerRadius(10)
                .padding()
                .shadow(color: Color.white.opacity(12), radius: 3, x: 3, y: 3)
            }
            .padding()
            .cornerRadius(15.0)
        }
    }
}

// MARK: - Ads App Card View

// View displaying individual ads app cards
struct AppCardView: View {
    var imageName: String
    var appName: String
    var appDescription: String
    var appURL: String

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(7)

            VStack(alignment: .leading) {
                Text(appName)
                    .font(.title3)
                Text(appDescription)
                    .font(.caption)
            }
            .frame(alignment: .leading)

            Spacer()

            // Try button
            Button(action: {
                if let url = URL(string: appURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Try")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                
            }
        }
    }
}

#Preview {
    ContentView()
}


/*
import SwiftUI
import StoreKit
import UserNotifications
import Combine

// ContentView
struct ContentView: View {
    @State private var showAdsAndAppFunctionality = false
    @State private var buttonStates = Array(repeating: false, count: 24) // Track button states for each hour
    @StateObject private var purchaseManager = PurchaseManager() // Purchase manager

    var body: some View {
        ZStack {
            
            // Background Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)),.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAdsAndAppFunctionality = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.white))
                                .padding()
                                .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                        }
                    }
                    // Purchase button for unlocking full version
               
                
                    
                    
                    Text("Take Medication")                        .font(.title.bold())
                        .foregroundColor(.white)
                        .padding()
                    
                    // Grid of 24 buttons, representing 24 hours of the day
                    let columns = Array(repeating: GridItem(.flexible()), count: 4) // 6x4 grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<24) { index in
                            Button(action: {
                                // Toggle button and handle notification scheduling/canceling
                                if buttonStates[index] {
                                    cancelNotification(for: index)
                                    buttonStates[index] = false
                                    saveButtonStates()
                                } else if buttonStates.filter({ $0 }).count < 3 || purchaseManager.unlimitedNotificationsUnlocked {
                                    buttonStates[index] = true
                                    scheduleNotification(for: index)
                                    saveButtonStates()
                                } else {
                                    print("Limit reached: Upgrade to unlock more notifications.")
                                }
                            }) {
                                VStack(spacing: 4) {
                                    // Main Container
                                    VStack(spacing: 2) {
                                        // Baby Icon with Background
                                        ZStack {
                                            Circle()
                                                .fill(buttonStates[index] ? Color(.systemMint).opacity(0.2) : Color(.systemBackground))
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Circle()
                                                        .stroke(buttonStates[index] ? Color(.systemMint) : Color(.systemGray4), lineWidth: 1.5)
                                                )
                                            
                                            // Baby emoji with animation
                                            Text("👶")
                                                .font(.system(size: 24))
                                                .scaleEffect(buttonStates[index] ? 1.1 : 1.0)
                                                .animation(.spring(response: 0.3), value: buttonStates[index])
                                        }
                                        .padding(.top, 4)
                                        
                                        // Time Display
                                        Text("\(index):00")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(buttonStates[index] ? Color(.systemMint) : .primary)
                                            .frame(width: 60, height: 30)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(buttonStates[index] ? Color(.systemMint).opacity(0.1) : Color(.systemGray6))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(buttonStates[index] ? Color(.systemMint).opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        buttonStates[index].toggle()
                                    }
                                }

                            }
                        }
                    }
                    
                    VStack{
                        Button(action: {
                            if let product = purchaseManager.products.first {
                                purchaseManager.buyProduct(product)
                            }
                        }) {
                            Text("Unlimited Reminders")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)))
                                .foregroundColor(.white)
                                .font(.title3.bold())
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color.white.opacity(1), radius: 3, x: 3, y: 3)
                        }
                        
                        // Restore Purchases button
                        Button(action: {
                            purchaseManager.restorePurchases()
                        }) {
                            Text("Restore Purchases")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .font(.title3.bold())
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)).opacity(12), radius: 3, x: 3, y: 3)
                        }
                        Spacer()
                    }
                    
                }
                .sheet(isPresented: $showAdsAndAppFunctionality) {
                    ShowAdsAndAppFunctionalityView(onConfirm: {
                        showAdsAndAppFunctionality = false
                    })
                }
//                .background(Color(.systemPink)) // Light pink background
                .onAppear {
                    loadButtonStates()
                    requestNotificationPermission()
                    purchaseManager.fetchProducts()
                }
                .padding()
            }
        }
    }

    // Save the button states to UserDefaults
    func saveButtonStates() {
        UserDefaults.standard.set(buttonStates, forKey: "ButtonStates")
    }

    // Load the button states from UserDefaults
    func loadButtonStates() {
        if let savedStates = UserDefaults.standard.array(forKey: "ButtonStates") as? [Bool] {
            buttonStates = savedStates
        }
    }

    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // Schedule a notification
    func scheduleNotification(for hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your medication for \(hour):00!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "medication_\(hour)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification for \(hour):00 scheduled successfully.")
            }
        }
    }

    // Cancel a notification
    func cancelNotification(for hour: Int) {
        let identifier = "medication_\(hour)"

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let remainingRequests = requests.filter { $0.identifier == identifier }
            if remainingRequests.isEmpty {
                print("Notification for \(hour):00 successfully canceled.")
            } else {
                print("Failed to cancel notification for \(hour):00.")
            }
        }
    }
}

// PurchaseManager class for handling in-app purchases
class PurchaseManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var unlimitedNotificationsUnlocked = false
    @Published var products: [SKProduct] = []
    
    private let productID = "com.babytimely.Unlimited" // Replace with your Product ID from App Store Connect
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Make sure to update on the main thread
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    // Restore previously made purchases
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // Ensure all updates are made on the main thread
                DispatchQueue.main.async {
                    self.unlimitedNotificationsUnlocked = true
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                if let error = transaction.error {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            default:
                break
            }
        }
    }
}

struct ShowAdsAndAppFunctionalityView: View {
    var onConfirm: () -> Void

    var body: some View {
        ScrollView {
            VStack {
                // Section header
                HStack {
                    Text("Ads & App Functionality")
                        .font(.title3.bold())
                    Spacer()
                }
                Divider().background(Color.gray)
                
                HStack {
                    Text("App Functionality")
                        .font(.title.bold())
                    Spacer()
                }

                Text("""
                • 24-Hour Buttons: Select the hour of the day to schedule medication reminders, set up to 3 medication reminders for free users.
                • Cancel Reminders: Easily cancel a scheduled reminder by pressing the corresponding hour button.
                • Unlimited Reminders: Purchase the Unlimited Reminders feature to set an unlimited number of reminders.
                •Restore Purchases: Restore your previously purchased Unlimited Reminders on any device, or if you reinstall the app on the same device.
                """)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .padding()

                // Ads section
                VStack {
                    // Ads header
                    HStack {
                        Text("App For You")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    // Ad image with link
               
                    
                    // App Cards for ads
                    VStack {
                        Divider().background(Color.gray)


                        AppCardView(imageName: "timetell", appName: "TimeTell", appDescription: "Announce the time every 30 seconds, no more guessing and checking your watch, for time-sensitive tasks.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "SingLoop", appName: "Sing LOOP", appDescription: "Record your voice effortlessly, and play it back in a loop.", appURL: "https://apps.apple.com/id/app/sing-l00p/id6480459464")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "loopspeak", appName: "LOOPSpeak", appDescription: "Type or paste your text, play in loop, and enjoy hands-free narration.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "insomnia", appName: "Insomnia Sheep", appDescription: "Design to ease your mind and help you relax leading up to sleep.", appURL: "https://apps.apple.com/id/app/insomnia-sheep/id6479727431")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "BST", appName: "Blink Screen Time", appDescription: "Using screens can reduce your blink rate to just 6 blinks per minute, leading to dry eyes and eye strain. Our app helps you maintain a healthy blink rate to prevent these issues and keep your eyes comfortable.", appURL: "https://apps.apple.com/id/app/blink-screen-time/id6587551095")
                        Divider().background(Color.gray)

                        AppCardView(imageName: "iprogram", appName: "iProgramMe", appDescription: "Custom affirmations, schedule notifications, stay inspired daily.", appURL: "https://apps.apple.com/id/app/iprogramme/id6470770935")
                        Divider().background(Color.gray)

                       
                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(15.0)

                // App functionality section
      

                Spacer()

                HStack {
                    Text("Take Medication is developed by Three Dollar.")
                        .font(.title3.bold())
                    Spacer()
                }

                // Close button
                Button("Close") {
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .font(.title3.bold())
                .cornerRadius(10)
                .padding()
                .shadow(color: Color.white.opacity(12), radius: 3, x: 3, y: 3)
            }
            .padding()
            .cornerRadius(15.0)
        }
    }
}

// MARK: - Ads App Card View

// View displaying individual ads app cards
struct AppCardView: View {
    var imageName: String
    var appName: String
    var appDescription: String
    var appURL: String

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(7)

            VStack(alignment: .leading) {
                Text(appName)
                    .font(.title3)
                Text(appDescription)
                    .font(.caption)
            }
            .frame(alignment: .leading)

            Spacer()

            // Try button
            Button(action: {
                if let url = URL(string: appURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Try")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    ContentView()
}


*/
