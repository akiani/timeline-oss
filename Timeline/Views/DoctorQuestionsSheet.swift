// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI

struct DoctorQuestionsSheet: View {
    @ObservedObject var cluster: CareEventCluster
    @Environment(\.dismiss) var dismiss
    @State private var isLoadingQuestions: Bool = false
    @State private var isGeneratingMoreQuestions: Bool = false
    @State private var questionsError: String? = nil
    @State private var questions: [DoctorQuestion] = []
    @State private var newQuestionIds: Set<UUID> = []
    @State private var expandedQuestions: Set<UUID> = []
    @State private var showingErrorAlert = false
    @State private var errorAlertMessage = ""
    
    private let doctorQuestionsService = DoctorQuestionsService.shared
    private let remindersService = RemindersService.shared
    
    var body: some View {
        questionsContentView
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.timelinePrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        remindersService.openRemindersApp()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.rectangle")
                            Text("Open Reminders")
                        }
                        .font(.subheadline)
                        .foregroundColor(.timelinePrimary)
                    }
                }
            }
            .background(Color.timelineBackground)
            .onAppear {
                if questions.isEmpty && !isLoadingQuestions {
                    generateQuestions()
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorAlertMessage)
            }
            .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    private var questionsContentView: some View {
        if isLoadingQuestions && questions.isEmpty {
            // Show loading view at full screen for proper centering
            initialLoadingView
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let error = questionsError {
                        errorView(error)
                    } else if !questions.isEmpty {
                        questionsListView
                    } else {
                        emptyQuestionsView
                    }
                }
                .padding(16)
            }
            .background(Color.timelineBackground)
        }
    }
    
    @ViewBuilder
    private var initialLoadingView: some View {
        DelightfulLoadingView(customMessages: [
            "Analyzing your records",
            "Finding patterns",
            "Crafting questions",
            "Personalizing advice",
            "Preparing insights"
        ])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 300)
    }
    
    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.timelineWarning)
            
            Text("Failed to Generate Questions")
                .font(.headline)
                .foregroundColor(.timelinePrimaryText)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.timelineSecondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                generateQuestions()
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.timelinePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private var questionsListView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .center, spacing: 12) {
                Text("Questions based on \(formattedDate(from: cluster.date)) records")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.timelinePrimaryText)
                    .multilineTextAlignment(.center)
                
                // Sorted by relevance indicator with instructions
                HStack {
                    Spacer()
                    Text("Sorted by relevance • Tap + to add to Reminders")
                        .font(.caption)
                        .foregroundColor(.timelineSecondaryText)
                    Spacer()
                }
            }
            .padding(.bottom, 8)
            
            // All questions in priority order
            let sortedQuestions = questions.sorted { q1, q2 in
                let priority1 = QuestionPriority(rawValue: q1.priority) ?? .low
                let priority2 = QuestionPriority(rawValue: q2.priority) ?? .low
                return priority1.sortOrder < priority2.sortOrder
            }
            
            VStack(spacing: 12) {
                ForEach(Array(sortedQuestions.enumerated()), id: \.element.id) { sortedIndex, question in
                    questionRowView(question: question, originalIndex: findQuestionIndex(question))
                        .padding(16)
                        .background(newQuestionIds.contains(question.id) ? Color.timelinePrimary.opacity(0.05) : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(newQuestionIds.contains(question.id) ? Color.timelinePrimary.opacity(0.3) : Color.timelineOutline, lineWidth: newQuestionIds.contains(question.id) ? 1.0 : 0.5)
                        )
                        .scaleEffect(newQuestionIds.contains(question.id) ? 1.02 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: newQuestionIds.contains(question.id))
                }
            }
            
            // Generate More button
            Button(action: {
                generateQuestions(generateMore: true)
            }) {
                HStack(spacing: 8) {
                    if isGeneratingMoreQuestions {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.timelinePrimary)
                    } else {
                        Image(systemName: "plus.circle")
                            .font(.subheadline)
                    }
                    Text(isGeneratingMoreQuestions ? "Generating More Questions..." : "Generate More Questions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.timelinePrimary.opacity(isGeneratingMoreQuestions ? 0.05 : 0.1))
                .foregroundColor(isGeneratingMoreQuestions ? .timelineSecondaryText : .timelinePrimary)
                .cornerRadius(8)
            }
            .disabled(isGeneratingMoreQuestions)
            .padding(.top, 8)
            
            // Footer disclaimer
            disclaimerView
        }
    }
    
    
    @ViewBuilder
    private func questionRowView(question: DoctorQuestion, originalIndex: Int) -> some View {
        let isExpanded = expandedQuestions.contains(question.id)
        
        VStack(alignment: .leading, spacing: 0) {
            // Main question row
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(question.question)
                        .font(.subheadline)
                        .foregroundColor(.timelinePrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        if let category = QuestionCategory(rawValue: question.category) {
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.timelineBackground)
                                .foregroundColor(.timelineSecondaryText)
                                .cornerRadius(6)
                        }
                        
                        if newQuestionIds.contains(question.id) {
                            Text("NEW")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.timelinePrimary)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedQuestions.remove(question.id)
                        } else {
                            expandedQuestions.insert(question.id)
                        }
                    }
                }
                
                Button(action: {
                    toggleReminderStatus(at: originalIndex)
                }) {
                    Image(systemName: question.isInReminders ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title3)
                        .foregroundColor(question.isInReminders ? .green : .timelinePrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text(question.whyAsk)
                        .font(.subheadline)
                        .foregroundColor(.timelineSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
            }
        }
    }
    
    
    @ViewBuilder
    private var disclaimerView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.footnote)
                .foregroundColor(.timelineSecondaryText)
                .padding(.top, 2)
            
            Text("AI-generated content for informational purposes only. Not medical advice. May be incomplete or inaccurate. Consult healthcare providers for medical decisions.")
                .font(.footnote)
                .foregroundColor(.timelineSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.timelineBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.timelineOutline.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var emptyQuestionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text("No Questions Needed")
                .font(.headline)
                .foregroundColor(.timelinePrimaryText)
            
            Text("These appear to be routine health records with no specific concerns or actionable items that require follow-up questions.")
                .font(.subheadline)
                .foregroundColor(.timelineSecondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                generateQuestions()
            }) {
                Text("Try Generating Questions Anyway")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.timelinePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateQuestions(generateMore: Bool = false) {
        if generateMore {
            isGeneratingMoreQuestions = true
        } else {
            isLoadingQuestions = true
        }
        questionsError = nil
        
        // Keep existing questions when generating more
        let existingQuestions = generateMore ? questions : []
        if !generateMore {
            questions = []
        }
        
        Task {
            do {
                let generatedQuestions = try await doctorQuestionsService.generateDoctorQuestions(
                    for: cluster,
                    excludingQuestions: existingQuestions
                )
                await MainActor.run {
                    if generateMore {
                        // Track new question IDs
                        let newIds = Set(generatedQuestions.map { $0.id })
                        self.newQuestionIds = newIds
                        
                        // Append new questions to existing ones
                        self.questions.append(contentsOf: generatedQuestions)
                        self.isGeneratingMoreQuestions = false
                        
                        // Clear "NEW" indicators after 10 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                self.newQuestionIds.removeAll()
                            }
                        }
                    } else {
                        self.questions = generatedQuestions
                        self.newQuestionIds.removeAll() // Clear any existing new indicators
                        self.isLoadingQuestions = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.questionsError = error.localizedDescription
                    if generateMore {
                        self.isGeneratingMoreQuestions = false
                    } else {
                        self.isLoadingQuestions = false
                    }
                }
            }
        }
    }
    
    private func toggleReminderStatus(at index: Int) {
        guard index >= 0 && index < questions.count else { return }
        
        let question = questions[index]
        
        Task {
            do {
                if question.isInReminders {
                    // Remove from Reminders
                    if let reminderID = question.reminderID {
                        try await remindersService.removeDoctorQuestionReminder(reminderID: reminderID)
                    }
                    await MainActor.run {
                        questions[index].isInReminders = false
                        questions[index].reminderID = nil
                    }
                } else {
                    // Add to Reminders
                    let reminderID = try await remindersService.createSingleDoctorQuestionReminder(
                        question: question,
                        clusterDate: cluster.date
                    )
                    await MainActor.run {
                        questions[index].isInReminders = true
                        questions[index].reminderID = reminderID
                    }
                }
            } catch {
                await MainActor.run {
                    errorAlertMessage = "Failed to update reminder: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func findQuestionIndex(_ question: DoctorQuestion) -> Int {
        return questions.firstIndex(where: { $0.id == question.id }) ?? 0
    }
    
    
    private func formattedDate(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
    
}
