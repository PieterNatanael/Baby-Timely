//
//  NotesView.swift
//  Time Tell
//
//  Created by Pieter Yoshua Natanael on 04/12/24.
//
import SwiftUI
import AVFoundation

// Main Content View
struct NotesView: View {
    @State private var AdsAndAppFunctionality = false
    @State private var showDeleteConfirmation = false
    @State private var selectedWorry: Worry?
    
    @State private var worries: [Worry] = []
    @State private var SoundEffect: AVAudioPlayer?
    @State private var defaults = UserDefaults.standard // UserDefaults for data persistence
    @StateObject private var viewModel = WorryViewModel()
    @State private var newWorryText = ""

    // DateFormatter for formatting dates
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    // Save worries to UserDefaults
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(worries) {
            defaults.set(encoded, forKey: "SavedWorries")
        }
    }

    // Load worries from UserDefaults
    func load() {
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: "SavedWorries") {
            if let loadedWorries = try? decoder.decode([Worry].self, from: data) {
                worries = loadedWorries
            }
        }
    }

    // Add a new worry and save data
    func addWorry() {
        let newWorry = Worry(text: newWorryText)
        worries.append(newWorry)
        newWorryText = ""
        save()
        playSoundEffect()
        showMessage(title: "Thank You!", message: "Thank you for sharing your notes.")
    }

    // Delete a worry and save data
    func deleteWorry(atOffsets offsets: IndexSet) {
        worries.remove(atOffsets: offsets)
        save()
    }

    // Play a sound effect
    func playSoundEffect() {
        if let soundURL = Bundle.main.url(forResource: "flute", withExtension: "mp3") {
            do {
                SoundEffect = try AVAudioPlayer(contentsOf: soundURL)
                SoundEffect?.play()
            } catch {
                print("Error loading clap sound file: \(error.localizedDescription)")
            }
        } else {
            print("Clap sound file not found.")
        }
    }

    // Show an alert message
    func showMessage(title: String, message: String) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            windowScene.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }

    // Toggle the realized status of a worry
    func toggleRealized(for worry: Worry) {
        if let index = worries.firstIndex(where: { $0.id == worry.id }) {
            worries[index].realized.toggle()
            save()
        }
    }
    

    var body: some View {
        ZStack {
            // Background Color Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1)), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        AdsAndAppFunctionality = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(.white))
                            .padding()
                            .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                    }
                }
               
                HStack {
                    Text("Medication Notes")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
                List {
                    ForEach(worries) { worry in
                        VStack(alignment: .leading) {
                            Text(worry.text)
                            HStack {
                                Text("Added: \(worry.timestamp, formatter: dateFormatter)")
                                Spacer()
                                Text("\(worry.daysAgo) days ago")
                                Button(action: {
                                    toggleRealized(for: worry)
                                }) {
                                    Image(systemName: worry.realized ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(worry.realized ? Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)) : .primary)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                Button(action: {
                                    selectedWorry = worry
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.title3.bold())
                                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .foregroundColor(worry.realized ? Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)) : .primary)
                        }
                    }
                    .onDelete(perform: deleteWorry)
                }
                .listStyle(PlainListStyle())
                
                TextField("Enter your notes", text: $newWorryText)
                    .padding()

                Button(action: addWorry) {
                    Text("Save Notes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(#colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1)))
                        .foregroundColor(.white)
                        .font(.title3.bold())
                        .cornerRadius(10)
                        .padding()
                        .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .onAppear {
                load()
            }
            .sheet(isPresented: $AdsAndAppFunctionality) {
                AdsAndAppFunctionalityView(onConfirm: {
                    AdsAndAppFunctionality = false
                })
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Notes"),
                    message: Text("Are you sure you want to delete this notes?"),
                    primaryButton: .destructive(Text("Yes")) {
                        if let selectedWorry = selectedWorry {
                            if let index = worries.firstIndex(where: { $0.id == selectedWorry.id }) {
                                worries.remove(at: index)
                            }
                        }
                        selectedWorry = nil
                        save()
                        playSoundEffect()
                    },
                    secondaryButton: .cancel(Text("No")) {
                        selectedWorry = nil
                    }
                )
            }
        }
    }
}

// Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(#colorLiteral(red: 0.9529411793, green: 0.9529411793, blue: 0.9725490212, alpha: 1)))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// Worry Model
struct Worry: Identifiable, Codable {
    var id = UUID()
    var text: String
    var realized = false
    var timestamp = Date()
    
    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
    }
}

// MARK: - Ads and App Functionality View

// View showing information about ads and the app functionality
struct AdsAndAppFunctionalityView: View {
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

                // Ads section
                VStack {
                    // Ads header
                    HStack {
                        Text("Apps for you")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    // Ad image with link
//                    ZStack {
//                        Image("threedollar")
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .cornerRadius(25)
//                            .clipped()
//                            .onTapGesture {
//                                if let url = URL(string: "https://b33.biz/three-dollar/") {
//                                    UIApplication.shared.open(url)
//                                }
//                            }
//                    }
                    
                    // App Cards for ads
                    VStack {
//                        Divider().background(Color.gray)
//
//                        AppCardView(imageName: "sos", appName: "SOS Light", appDescription: "SOS Light is designed to maximize the chances of getting help in emergency situations.", appURL: "https://apps.apple.com/app/s0s-light/id6504213303")
//                        Divider().background(Color.gray)
//                        AppCardView(imageName: "takemedication", appName: "Take Medication", appDescription: "Just press any of the 24 buttons, each representing an hour of the day, and you'll get timely reminders to take your medication. It's easy, quick, and ensures you never miss a dose!", appURL: "https://apps.apple.com/id/app/take-medication/id6736924598")
//                        Divider().background(Color.gray)
//
//                        AppCardView(imageName: "timetell", appName: "TimeTell", appDescription: "Announce the time every 30 seconds, no more guessing and checking your watch, for time-sensitive tasks.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        CardView(imageName: "SingLoop", appName: "Sing LOOP", appDescription: "Record your voice effortlessly, and play it back in a loop.", appURL: "https://apps.apple.com/id/app/sing-l00p/id6480459464")
                        Divider().background(Color.gray)

                        CardView(imageName: "loopspeak", appName: "LOOPSpeak", appDescription: "Type or paste your text, play in loop, and enjoy hands-free narration.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

//                        AppCardView(imageName: "insomnia", appName: "Insomnia Sheep", appDescription: "Design to ease your mind and help you relax leading up to sleep.", appURL: "https://apps.apple.com/id/app/insomnia-sheep/id6479727431")
//                        Divider().background(Color.gray)


                        CardView(imageName: "iprogram", appName: "iProgramMe", appDescription: "Custom affirmations, schedule notifications, stay inspired daily.", appURL: "https://apps.apple.com/id/app/iprogramme/id6470770935")
                        Divider().background(Color.gray)

                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(15.0)

                // App functionality section
                HStack {
                    Text("App Functionality")
                        .font(.title.bold())
                    Spacer()
                }

                Text("""
                • Users can enter their notes into a text field and save them.
                • Saved notes are displayed in a list with details such as the date added and how many days ago they were added.
                • Each notes in the list has a 'checkmark' button that users can tap to mark the notes as resolved.
                • Users can delete notes by tapping the "trash" button next to each notes, with a confirmation dialog to ensure they want to delete it permanently.
                • The app automatically calculates and displays the number of days since each notes was added.
                •We do not collect data, so there's no need to worry
                """)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .padding()

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
struct CardView: View {
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


//viewmode;
class WorryViewModel: ObservableObject {
    @Published var worries: [Worry] = []

    private let dataManager = DataManager()

    init() {
        loadWorries()
    }

    func loadWorries() {
        worries = dataManager.loadWorries()
    }

    func saveWorry(_ worry: Worry) {
        dataManager.saveWorry(worry)
        loadWorries()
    }

    func deleteWorry(atOffsets offsets: IndexSet) {
        dataManager.deleteWorry(atOffsets: offsets)
        loadWorries()
    }
}



//data manager
class DataManager {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadWorries() -> [Worry] {
        guard let data = defaults.data(forKey: "SavedWorries") else { return [] }
        guard let loadedWorries = try? decoder.decode([Worry].self, from: data) else { return [] }
        return loadedWorries
    }

    func saveWorry(_ worry: Worry) {
        var savedWorries = loadWorries()
        savedWorries.append(worry)
        if let encoded = try? encoder.encode(savedWorries) {
            defaults.set(encoded, forKey: "SavedWorries")
        }
    }

    func deleteWorry(atOffsets offsets: IndexSet) {
        var savedWorries = loadWorries()
        savedWorries.remove(atOffsets: offsets)
        if let encoded = try? encoder.encode(savedWorries) {
            defaults.set(encoded, forKey: "SavedWorries")
        }
    }
}




// Preview
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
    }
}


/*
//works but toggle for worry realized back to no everytime restart
import SwiftUI
import AVFoundation

// Main Content View
struct NotesView: View {
    @State private var AdsAndAppFunctionality = false
    @State private var showDeleteConfirmation = false
    @State private var selectedWorry: Worry?
    
    @State private var worries: [Worry] = []
    @State private var SoundEffect: AVAudioPlayer?
    @State private var defaults = UserDefaults.standard // UserDefaults for data persistence
    @StateObject private var viewModel = WorryViewModel()
    @State private var newWorryText = ""

    // DateFormatter for formatting dates
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    // Save worries to UserDefaults
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(worries) {
            defaults.set(encoded, forKey: "SavedWorries")
        }
    }

    // Load worries from UserDefaults
    func load() {
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: "SavedWorries") {
            if let loadedWorries = try? decoder.decode([Worry].self, from: data) {
                worries = loadedWorries
            }
        }
    }

    // Add a new worry and save data
    func addWorry() {
        let newWorry = Worry(text: newWorryText)
        worries.append(newWorry)
        newWorryText = ""
        save()
        playSoundEffect()
        showMessage(title: "Thank You!", message: "Thank you for sharing your notes.")
    }

    // Delete a worry and save data
    func deleteWorry(atOffsets offsets: IndexSet) {
        worries.remove(atOffsets: offsets)
        save()
    }

    // Play a sound effect
    func playSoundEffect() {
        if let soundURL = Bundle.main.url(forResource: "flute", withExtension: "mp3") {
            do {
                SoundEffect = try AVAudioPlayer(contentsOf: soundURL)
                SoundEffect?.play()
            } catch {
                print("Error loading clap sound file: \(error.localizedDescription)")
            }
        } else {
            print("Clap sound file not found.")
        }
    }

    // Show an alert message
    func showMessage(title: String, message: String) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            windowScene.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }

    // Toggle the realized status of a worry
    func toggleRealized(for worry: Worry) {
        if let index = worries.firstIndex(where: { $0.id == worry.id }) {
            worries[index].realized.toggle()
        }
    }
    

    var body: some View {
        ZStack {
            // Background Color Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 0.5704585314, green: 0.5704723597, blue: 0.5704649091, alpha: 1)), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        AdsAndAppFunctionality = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(.white))
                            .padding()
                            .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                    }
                }
               
                HStack {
                    Text("Medication Notes")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
                List {
                    ForEach(worries) { worry in
                        VStack(alignment: .leading) {
                            Text(worry.text)
                            HStack {
                                Text("Added: \(worry.timestamp, formatter: dateFormatter)")
                                Spacer()
                                Text("\(worry.daysAgo) days ago")
                                Button(action: {
                                    toggleRealized(for: worry)
                                }) {
                                    Image(systemName: worry.realized ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(worry.realized ? Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)) : .primary)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                Button(action: {
                                    selectedWorry = worry
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.title3.bold())
                                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .foregroundColor(worry.realized ? Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)) : .primary)
                        }
                    }
                    .onDelete(perform: deleteWorry)
                }
                .listStyle(PlainListStyle())
                
                TextField("Enter your notes", text: $newWorryText)
                    .padding()

                Button(action: addWorry) {
                    Text("Save Notes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)))
                        .foregroundColor(.white)
                        .font(.title3.bold())
                        .cornerRadius(10)
                        .padding()
                        .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .onAppear {
                load()
            }
            .sheet(isPresented: $AdsAndAppFunctionality) {
                AdsAndAppFunctionalityView(onConfirm: {
                    AdsAndAppFunctionality = false
                })
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Notes"),
                    message: Text("Are you sure you want to delete this notes?"),
                    primaryButton: .destructive(Text("Yes")) {
                        if let selectedWorry = selectedWorry {
                            if let index = worries.firstIndex(where: { $0.id == selectedWorry.id }) {
                                worries.remove(at: index)
                            }
                        }
                        selectedWorry = nil
                        save()
                        playSoundEffect()
                    },
                    secondaryButton: .cancel(Text("No")) {
                        selectedWorry = nil
                    }
                )
            }
        }
    }
}

// Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(#colorLiteral(red: 0.9529411793, green: 0.9529411793, blue: 0.9725490212, alpha: 1)))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// Worry Model
struct Worry: Identifiable, Codable {
    var id = UUID()
    var text: String
    var realized = false
    var timestamp = Date()
    
    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
    }
}

// MARK: - Ads and App Functionality View

// View showing information about ads and the app functionality
struct AdsAndAppFunctionalityView: View {
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

                // Ads section
                VStack {
                    // Ads header
                    HStack {
                        Text("Apps for you")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    // Ad image with link
//                    ZStack {
//                        Image("threedollar")
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .cornerRadius(25)
//                            .clipped()
//                            .onTapGesture {
//                                if let url = URL(string: "https://b33.biz/three-dollar/") {
//                                    UIApplication.shared.open(url)
//                                }
//                            }
//                    }
                    
                    // App Cards for ads
                    VStack {
//                        Divider().background(Color.gray)
//
//                        AppCardView(imageName: "sos", appName: "SOS Light", appDescription: "SOS Light is designed to maximize the chances of getting help in emergency situations.", appURL: "https://apps.apple.com/app/s0s-light/id6504213303")
//                        Divider().background(Color.gray)
//                        AppCardView(imageName: "takemedication", appName: "Take Medication", appDescription: "Just press any of the 24 buttons, each representing an hour of the day, and you'll get timely reminders to take your medication. It's easy, quick, and ensures you never miss a dose!", appURL: "https://apps.apple.com/id/app/take-medication/id6736924598")
//                        Divider().background(Color.gray)
//
//                        AppCardView(imageName: "timetell", appName: "TimeTell", appDescription: "Announce the time every 30 seconds, no more guessing and checking your watch, for time-sensitive tasks.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        CardView(imageName: "SingLoop", appName: "Sing LOOP", appDescription: "Record your voice effortlessly, and play it back in a loop.", appURL: "https://apps.apple.com/id/app/sing-l00p/id6480459464")
                        Divider().background(Color.gray)

                        CardView(imageName: "loopspeak", appName: "LOOPSpeak", appDescription: "Type or paste your text, play in loop, and enjoy hands-free narration.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

//                        AppCardView(imageName: "insomnia", appName: "Insomnia Sheep", appDescription: "Design to ease your mind and help you relax leading up to sleep.", appURL: "https://apps.apple.com/id/app/insomnia-sheep/id6479727431")
//                        Divider().background(Color.gray)


                        CardView(imageName: "iprogram", appName: "iProgramMe", appDescription: "Custom affirmations, schedule notifications, stay inspired daily.", appURL: "https://apps.apple.com/id/app/iprogramme/id6470770935")
                        Divider().background(Color.gray)

                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(15.0)

                // App functionality section
                HStack {
                    Text("App Functionality")
                        .font(.title.bold())
                    Spacer()
                }

                Text("""
                • Users can enter their notes into a text field and save them.
                • Saved notes are displayed in a list with details such as the date added and how many days ago they were added.
                • Each notes in the list has a 'checkmark' button that users can tap to mark the notes as resolved.
                • Users can delete notes by tapping the "trash" button next to each notes, with a confirmation dialog to ensure they want to delete it permanently.
                • The app automatically calculates and displays the number of days since each notes was added.
                •We do not collect data, so there's no need to worry
                """)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .padding()

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
struct CardView: View {
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


//viewmode;
class WorryViewModel: ObservableObject {
    @Published var worries: [Worry] = []

    private let dataManager = DataManager()

    init() {
        loadWorries()
    }

    func loadWorries() {
        worries = dataManager.loadWorries()
    }

    func saveWorry(_ worry: Worry) {
        dataManager.saveWorry(worry)
        loadWorries()
    }

    func deleteWorry(atOffsets offsets: IndexSet) {
        dataManager.deleteWorry(atOffsets: offsets)
        loadWorries()
    }
}



//data manager
class DataManager {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadWorries() -> [Worry] {
        guard let data = defaults.data(forKey: "SavedWorries") else { return [] }
        guard let loadedWorries = try? decoder.decode([Worry].self, from: data) else { return [] }
        return loadedWorries
    }

    func saveWorry(_ worry: Worry) {
        var savedWorries = loadWorries()
        savedWorries.append(worry)
        if let encoded = try? encoder.encode(savedWorries) {
            defaults.set(encoded, forKey: "SavedWorries")
        }
    }

    func deleteWorry(atOffsets offsets: IndexSet) {
        var savedWorries = loadWorries()
        savedWorries.remove(atOffsets: offsets)
        if let encoded = try? encoder.encode(savedWorries) {
            defaults.set(encoded, forKey: "SavedWorries")
        }
    }
}




// Preview
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
    }
}

*/
/*
//works but want try merger with data manager and view model
import SwiftUI
import AVFoundation

// Main Content View
struct NotesView: View {
    @State private var AdsAndAppFunctionality = false
    @State private var showDeleteConfirmation = false
    @State private var selectedWorry: Worry?
    
    @State private var worries: [Worry] = []
    @State private var SoundEffect: AVAudioPlayer?
    @State private var defaults = UserDefaults.standard // UserDefaults for data persistence
    @StateObject private var viewModel = WorryViewModel()
    @State private var newWorryText = ""

    // DateFormatter for formatting dates
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    // Save worries to UserDefaults
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(worries) {
            defaults.set(encoded, forKey: "SavedWorries")
        }
    }

    // Load worries from UserDefaults
    func load() {
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: "SavedWorries") {
            if let loadedWorries = try? decoder.decode([Worry].self, from: data) {
                worries = loadedWorries
            }
        }
    }

    // Add a new worry and save data
    func addWorry() {
        let newWorry = Worry(text: newWorryText)
        worries.append(newWorry)
        newWorryText = ""
        save()
        playSoundEffect()
        showMessage(title: "Thank You!", message: "Thank you for sharing your notes.")
    }

    // Delete a worry and save data
    func deleteWorry(atOffsets offsets: IndexSet) {
        worries.remove(atOffsets: offsets)
        save()
    }

    // Play a sound effect
    func playSoundEffect() {
        if let soundURL = Bundle.main.url(forResource: "flute", withExtension: "mp3") {
            do {
                SoundEffect = try AVAudioPlayer(contentsOf: soundURL)
                SoundEffect?.play()
            } catch {
                print("Error loading clap sound file: \(error.localizedDescription)")
            }
        } else {
            print("Clap sound file not found.")
        }
    }

    // Show an alert message
    func showMessage(title: String, message: String) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            windowScene.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }

    // Toggle the realized status of a worry
    func toggleRealized(for worry: Worry) {
        if let index = worries.firstIndex(where: { $0.id == worry.id }) {
            worries[index].realized.toggle()
        }
    }
    

    var body: some View {
        ZStack {
            // Background Color Gradient
            LinearGradient(colors: [Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        AdsAndAppFunctionality = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(.white))
                            .padding()
                            .shadow(color: Color.black.opacity(0.6), radius: 5, x: 0, y: 2)
                    }
                }
                Spacer()
                HStack {
                    Text("Time Tell Notes")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
                List {
                    ForEach(worries) { worry in
                        VStack(alignment: .leading) {
                            Text(worry.text)
                            HStack {
                                Text("Added: \(worry.timestamp, formatter: dateFormatter)")
                                Spacer()
                                Text("\(worry.daysAgo) days ago")
                                Button(action: {
                                    toggleRealized(for: worry)
                                }) {
                                    Image(systemName: worry.realized ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(worry.realized ? Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)) : .primary)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                Button(action: {
                                    selectedWorry = worry
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.title3.bold())
                                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .foregroundColor(worry.realized ? Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)) : .primary)
                        }
                    }
                    .onDelete(perform: deleteWorry)
                }
                .listStyle(PlainListStyle())
                
                TextField("Enter your notes", text: $newWorryText)
                    .padding()

                Button(action: addWorry) {
                    Text("Save Notes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(#colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)))
                        .foregroundColor(.white)
                        .font(.title3.bold())
                        .cornerRadius(10)
                        .padding()
                        .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .onAppear {
                load()
            }
            .sheet(isPresented: $AdsAndAppFunctionality) {
                AdsAndAppFunctionalityView(onConfirm: {
                    AdsAndAppFunctionality = false
                })
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Notes"),
                    message: Text("Are you sure you want to delete this notes?"),
                    primaryButton: .destructive(Text("Yes")) {
                        if let selectedWorry = selectedWorry {
                            if let index = worries.firstIndex(where: { $0.id == selectedWorry.id }) {
                                worries.remove(at: index)
                            }
                        }
                        selectedWorry = nil
                        save()
                        playSoundEffect()
                    },
                    secondaryButton: .cancel(Text("No")) {
                        selectedWorry = nil
                    }
                )
            }
        }
    }
}

// Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(#colorLiteral(red: 0.9529411793, green: 0.9529411793, blue: 0.9725490212, alpha: 1)))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// Worry Model
struct Worry: Identifiable, Codable {
    var id = UUID()
    var text: String
    var realized = false
    var timestamp = Date()
    
    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
    }
}

// MARK: - Ads and App Functionality View

// View showing information about ads and the app functionality
struct AdsAndAppFunctionalityView: View {
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

                // Ads section
                VStack {
                    // Ads header
                    HStack {
                        Text("Apps for you")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    // Ad image with link
//                    ZStack {
//                        Image("threedollar")
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .cornerRadius(25)
//                            .clipped()
//                            .onTapGesture {
//                                if let url = URL(string: "https://b33.biz/three-dollar/") {
//                                    UIApplication.shared.open(url)
//                                }
//                            }
//                    }
                    
                    // App Cards for ads
                    VStack {
//                        Divider().background(Color.gray)
//
//                        AppCardView(imageName: "sos", appName: "SOS Light", appDescription: "SOS Light is designed to maximize the chances of getting help in emergency situations.", appURL: "https://apps.apple.com/app/s0s-light/id6504213303")
//                        Divider().background(Color.gray)
//                        AppCardView(imageName: "takemedication", appName: "Take Medication", appDescription: "Just press any of the 24 buttons, each representing an hour of the day, and you'll get timely reminders to take your medication. It's easy, quick, and ensures you never miss a dose!", appURL: "https://apps.apple.com/id/app/take-medication/id6736924598")
//                        Divider().background(Color.gray)
//
//                        AppCardView(imageName: "timetell", appName: "TimeTell", appDescription: "Announce the time every 30 seconds, no more guessing and checking your watch, for time-sensitive tasks.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

                        CardView(imageName: "SingLoop", appName: "Sing LOOP", appDescription: "Record your voice effortlessly, and play it back in a loop.", appURL: "https://apps.apple.com/id/app/sing-l00p/id6480459464")
                        Divider().background(Color.gray)

                        CardView(imageName: "loopspeak", appName: "LOOPSpeak", appDescription: "Type or paste your text, play in loop, and enjoy hands-free narration.", appURL: "https://apps.apple.com/id/app/loopspeak/id6473384030")
                        Divider().background(Color.gray)

//                        AppCardView(imageName: "insomnia", appName: "Insomnia Sheep", appDescription: "Design to ease your mind and help you relax leading up to sleep.", appURL: "https://apps.apple.com/id/app/insomnia-sheep/id6479727431")
//                        Divider().background(Color.gray)


                        CardView(imageName: "iprogram", appName: "iProgramMe", appDescription: "Custom affirmations, schedule notifications, stay inspired daily.", appURL: "https://apps.apple.com/id/app/iprogramme/id6470770935")
                        Divider().background(Color.gray)

                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(15.0)

                // App functionality section
                HStack {
                    Text("App Functionality")
                        .font(.title.bold())
                    Spacer()
                }

                Text("""
                • Users can enter their notes into a text field and save them.
                • Saved notes are displayed in a list with details such as the date added and how many days ago they were added.
                • Each notes in the list has a 'checkmark' button that users can tap to mark the notes as resolved.
                • Users can delete notes by tapping the "trash" button next to each notes, with a confirmation dialog to ensure they want to delete it permanently.
                • The app automatically calculates and displays the number of days since each notes was added.
                •We do not collect data, so there's no need to worry
                """)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .padding()

                Spacer()

                HStack {
                    Text("Time Tell is developed by Three Dollar.")
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
struct CardView: View {
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


// Preview
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
    }
}
*/
