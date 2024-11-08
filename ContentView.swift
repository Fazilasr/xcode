//
//  ContentView.swift
//  Sounds
//
//  Created by Fazil on 07/11/24.
//



import SwiftUI
import AVFoundation

struct SoundPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Enhanced Sound data model
struct Sound: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let category: SoundCategory
    let description: String
    let colorTheme: Color
}

enum SoundCategory: String, CaseIterable {
    case nature = "Nature"
    case weather = "Weather"
    case ambient = "Ambient"
    case meditation = "Meditation"
    
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .weather: return "cloud.fill"
        case .ambient: return "sparkles"
        case .meditation: return "heart.circle.fill"
        }
    }
}

class SoundManager: ObservableObject {
    @Published var audioPlayers: [String: AVAudioPlayer] = [:]
    @Published var isPlaying = false
    @Published var volume: Float = 0.5
    @Published var isLooping = false
    @Published var fadeInDuration: Double = 2.0
    @Published var fadeOutDuration: Double = 2.0
    @Published var timer: Timer?
    @Published var sleepTimerMinutes: Int = 0
    
    let sounds: [Sound] = [
        Sound(name: "rain", icon: "cloud.rain.fill", category: .weather, description: "Gentle rainfall to help you relax", colorTheme: .blue),
        Sound(name: "thunder", icon: "cloud.bolt.fill", category: .weather, description: "Distant thunder sounds", colorTheme: .purple),
        Sound(name: "breeze", icon: "wind", category: .nature, description: "Soft wind through trees", colorTheme: .green),
        Sound(name: "crickets", icon: "ant.fill", category: .nature, description: "Evening cricket chorus", colorTheme: .green),
        Sound(name: "waves", icon: "water.waves", category: .nature, description: "Calming ocean waves", colorTheme: .blue),
        Sound(name: "forest", icon: "tree.fill", category: .nature, description: "Peaceful forest ambience", colorTheme: .green),
        Sound(name: "fireplace", icon: "flame.fill", category: .ambient, description: "Cozy fireplace crackle", colorTheme: .orange),
        Sound(name: "whitenoise", icon: "waveform", category: .ambient, description: "Soothing white noise", colorTheme: .gray),
        Sound(name: "meditation", icon: "heart.circle.fill", category: .meditation, description: "Peaceful meditation bells", colorTheme: .purple),
        Sound(name: "chimes", icon: "bell.fill", category: .meditation, description: "Gentle wind chimes", colorTheme: .purple)
    ]
    
    func playSound(named: String) {
        guard let url = Bundle.main.url(forResource: named, withExtension: "mp3") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0
            player.numberOfLoops = isLooping ? -1 : 0
            player.play()
            
            // Fade in
            withAnimation(.linear(duration: fadeInDuration)) {
                player.volume = volume
            }
            
            audioPlayers[named] = player
            isPlaying = true
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    func stopSound(named: String) {
        guard let player = audioPlayers[named] else { return }
        
        // Fade out
        withAnimation(.linear(duration: fadeOutDuration)) {
            player.volume = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
            player.stop()
            self.audioPlayers.removeValue(forKey: named)
            if self.audioPlayers.isEmpty {
                self.isPlaying = false
            }
        }
    }
    
    func updateVolume() {
        audioPlayers.values.forEach { $0.volume = volume }
    }
    
    func toggleLoop() {
        isLooping.toggle()
        audioPlayers.values.forEach { $0.numberOfLoops = isLooping ? -1 : 0 }
    }
    
    func startSleepTimer() {
        stopSleepTimer()
        guard sleepTimerMinutes > 0 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: Double(sleepTimerMinutes * 60), repeats: false) { [weak self] _ in
            self?.audioPlayers.keys.forEach { self?.stopSound(named: $0) }
            self?.timer = nil
        }
    }
    
    func stopSleepTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct ContentView: View {
    @StateObject private var soundManager = SoundManager()
    @State private var selectedSounds: Set<Sound> = []
    @State private var selectedCategory: SoundCategory = .nature
    @State private var showSettings = false
    @State private var showFavorites = false
    @State private var favorites: Set<Sound> = []
    
    var filteredSounds: [Sound] {
        soundManager.sounds.filter { showFavorites ? favorites.contains($0) : $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        selectedCategory.gradientColors.0,
                        selectedCategory.gradientColors.1
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Enhanced Category Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            Button(action: { showFavorites.toggle() }) {
                                CategoryButton(
                                    icon: "star.fill",
                                    title: "Favorites",
                                    isSelected: showFavorites
                                )
                            }
                            
                            ForEach(SoundCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    icon: category.icon,
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category && !showFavorites
                                )
                                .onTapGesture {
                                    selectedCategory = category
                                    showFavorites = false
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Enhanced Sound Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredSounds) { sound in
                                EnhancedSoundButton(
                                    sound: sound,
                                    isSelected: selectedSounds.contains(sound),
                                    isFavorite: favorites.contains(sound),
                                    onPlay: {
                                        toggleSound(sound)
                                    },
                                    onFavorite: {
                                        toggleFavorite(sound)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Enhanced Player Controls
                    if !selectedSounds.isEmpty {
                        EnhancedPlayerControlsView(
                            soundManager: soundManager,
                            selectedSounds: $selectedSounds
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationTitle("Soothing Sounds")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                EnhancedSettingsView(soundManager: soundManager)
            }
        }
    }
    
    private func toggleSound(_ sound: Sound) {
        if selectedSounds.contains(sound) {
            selectedSounds.remove(sound)
            soundManager.stopSound(named: sound.name)
        } else {
            selectedSounds.insert(sound)
            soundManager.playSound(named: sound.name)
        }
    }
    
    private func toggleFavorite(_ sound: Sound) {
        if favorites.contains(sound) {
            favorites.remove(sound)
        } else {
            favorites.insert(sound)
        }
    }
}

struct CategoryButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(title)
                .font(.subheadline)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.blue.opacity(0.2))
        )
        .foregroundColor(isSelected ? .white : .primary)
        .animation(.spring(), value: isSelected)
    }
}

struct EnhancedSoundButton: View {
    let sound: Sound
    let isSelected: Bool
    let isFavorite: Bool
    let onPlay: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                VStack {
                    Image(systemName: sound.icon)
                        .font(.system(size: 36))
                        .padding(.top, 20)
                    
                    Text(sound.name.capitalized)
                        .font(.headline)
                    
                    Text(sound.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                }
                
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .font(.system(size: 20))
                        .padding(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? sound.colorTheme : Color.clear, lineWidth: 2)
                )
        )
        .shadow(radius: isSelected ? 8 : 4)
        .onTapGesture(perform: onPlay)
        .animation(.spring(), value: isSelected)
    }
}

struct EnhancedPlayerControlsView: View {
    @ObservedObject var soundManager: SoundManager
    @Binding var selectedSounds: Set<Sound>
    
    var body: some View {
        VStack(spacing: 16) {
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedSounds)) { sound in
                        HStack {
                            Image(systemName: sound.icon)
                            Text(sound.name.capitalized)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(sound.colorTheme.opacity(0.2))
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            HStack {
                Image(systemName: "speaker.fill")
                Slider(value: $soundManager.volume, in: 0...1) { _ in
                    soundManager.updateVolume()
                }
                Image(systemName: "speaker.wave.3.fill")
            }
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: { soundManager.toggleLoop() }) {
                    VStack {
                        Image(systemName: soundManager.isLooping ? "repeat.circle.fill" : "repeat")
                            .font(.title2)
                        Text("Loop")
                            .font(.caption)
                    }
                }
                .foregroundColor(soundManager.isLooping ? .blue : .primary)
                
                Button(action: {
                    for sound in selectedSounds {
                        soundManager.stopSound(named: sound.name)
                    }
                    selectedSounds.removeAll()
                }) {
                    VStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.title)
                        Text("Stop All")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Material.ultraThinMaterial)
    }
}

struct EnhancedSettingsView: View {
    @ObservedObject var soundManager: SoundManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playback")) {
                    Toggle("Loop Sounds", isOn: $soundManager.isLooping)
                    
                    VStack(alignment: .leading) {
                        Text("Master Volume")
                        Slider(value: $soundManager.volume, in: 0...1) { _ in
                            soundManager.updateVolume()
                        }
                    }
                }
                
                Section(header: Text("Sleep Timer")) {
                    Picker("Timer Duration", selection: $soundManager.sleepTimerMinutes) {
                        Text("Off").tag(0)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                    }
                    
                    if soundManager.sleepTimerMinutes > 0 {
                        Button("Start Timer") {
                            soundManager.startSleepTimer()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                
                Section(header: Text("Sound Transitions")) {
                    VStack(alignment: .leading) {
                        Text("Fade In Duration: \(Int(soundManager.fadeInDuration))s")
                        Slider(value: $soundManager.fadeInDuration, in: 0...5, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                                                Text("Fade Out Duration: \(Int(soundManager.fadeOutDuration))s")
                                                Slider(value: $soundManager.fadeOutDuration, in: 0...5, step: 1)
                                            }
                                        }
                                    }
                                    
                                    Section(header: Text("App Info")) {
                                        HStack {
                                            Text("Version")
                                            Spacer()
                                            Text("2.0.0")
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        NavigationLink(destination: AboutView()) {
                                            Text("About")
                                        }
                                        
                                        Link("Rate the App", destination: URL(string: "https://apps.apple.com")!)
                                    }
                                }
                                .navigationTitle("Settings")
                                .navigationBarItems(
                                    trailing: Button("Done") {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                )
                            }
                        }
                    

                    struct AboutView: View {
                        var body: some View {
                            List {
                                Section(header: Text("About the App")) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Soothing Sounds")
                                            .font(.title2)
                                            .bold()
                                        
                                        Text("A peaceful collection of natural and ambient sounds to help you relax, focus, or sleep better.")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                Section(header: Text("How to Use")) {
                                    InfoRow(icon: "play.circle.fill", title: "Play Sounds", description: "Tap any sound card to play. You can play multiple sounds at once.")
                                    InfoRow(icon: "slider.horizontal.3", title: "Adjust Volume", description: "Use the slider to control individual sound volumes.")
                                    InfoRow(icon: "timer", title: "Sleep Timer", description: "Set a timer to automatically stop playback.")
                                    InfoRow(icon: "star.fill", title: "Favorites", description: "Save your favorite sound combinations for quick access.")
                                }
                            }
                            .navigationTitle("About")
                        }
                    }

                    struct InfoRow: View {
                        let icon: String
                        let title: String
                        let description: String
                        
                        var body: some View {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: icon)
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    Text(title)
                                        .font(.headline)
                                }
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Extension to provide gradient colors for categories
                    extension SoundCategory {
                        var gradientColors: (Color, Color) {
                            switch self {
                            case .nature:
                                return (Color.green.opacity(0.2), Color.blue.opacity(0.1))
                            case .weather:
                                return (Color.blue.opacity(0.2), Color.purple.opacity(0.1))
                            case .ambient:
                                return (Color.orange.opacity(0.2), Color.yellow.opacity(0.1))
                            case .meditation:
                                return (Color.purple.opacity(0.2), Color.pink.opacity(0.1))
                            }
                        }
                    }

                    // Extension for haptic feedback
                    extension UIImpactFeedbackGenerator {
                        static func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
                            let generator = UIImpactFeedbackGenerator(style: style)
                            generator.prepare()
                            generator.impactOccurred()
                        }
                    }

                    // Audio Session Configuration
                    extension SoundManager {
                        func configureAudioSession() {
                            do {
                                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                                try AVAudioSession.sharedInstance().setActive(true)
                            } catch {
                                print("Failed to configure audio session: \(error.localizedDescription)")
                            }
                        }
                        
                        func cleanupAudioSession() {
                            do {
                                try AVAudioSession.sharedInstance().setActive(false)
                            } catch {
                                print("Failed to deactivate audio session: \(error.localizedDescription)")
                            }
                        }
                    }

                    // Convenience methods for sound mixing
                    extension SoundManager {
                        func saveCurrentMix(name: String) {
                            // Implementation for saving current playing sounds as a mix
                            let currentMix = audioPlayers.keys.map { $0 }
                            // Save to UserDefaults or other persistent storage
                        }
                        
                        func loadMix(name: String) {
                            // Implementation for loading a saved mix
                            // Retrieve from storage and play saved sounds
                        }
                    }

                
