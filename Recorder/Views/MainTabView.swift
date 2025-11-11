import SwiftUI

struct MainTabView: View {
    @ObservedObject var recordingViewModel: RecordingViewModel
    @ObservedObject var notesListViewModel: NotesListViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    init(
        recordingViewModel: RecordingViewModel,
        notesListViewModel: NotesListViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.recordingViewModel = recordingViewModel
        self.notesListViewModel = notesListViewModel
        self.settingsViewModel = settingsViewModel
    }
    
    var body: some View {
        TabView {
            RecordingView(viewModel: recordingViewModel)
                .tabItem {
                    Label("tab.recording", systemImage: "mic")
                }
                .tag(0)

            NotesListView(viewModel: notesListViewModel)
                .tabItem {
                    Label("tab.notes", systemImage: "list.bullet")
                }
                .tag(1)

            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label("tab.settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tabViewStyle(.automatic)
        .tint(Color(hex: "3b82f6")) // Primary color for selected tab
    }
}
