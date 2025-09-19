// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

/// Centralized configuration for all AI prompts used in the Timeline app
struct PromptsConfiguration {
    
    // MARK: - Timeline Generation
    
    /// Prompt for generating brief timeline event summaries from FHIR clusters
    static func clusterTimelinePrompt(date: String, fhirResourcesJson: String) -> String {
        return """
        Below are FHIR health records for a patient.
        ================================================
        \(fhirResourcesJson)
        ================================================
        Your task is to analyze these FHIR health records to:
        1. Create a single and terse (max 20 words) cohesive event description that summarizes what happened in layperson non-medical language.
        2. Never include any personally identifiable information (PII)
        3. Focus only on the most significant medical events - skip minor details and routine findings.
        4. Choose an appropriate SF Symbol icon name that best represents the overall health activity.
        5. Identify key FHIR records that contain significant natural language text written by healthcare providers (artifacts).
        
        ARTIFACTS: Look for FHIR records containing substantial natural language text such as:
        - Radiology reports (DiagnosticReport with imaging findings)
        - Pathology reports (DiagnosticReport with tissue analysis)
        - Genomics reports (DiagnosticReport with genetic findings)
        - Clinical notes and discharge summaries (DocumentReference)
        - Physician procedure notes with detailed descriptions
        - Laboratory reports with narrative findings
        - If there are multiple records with the same information, choose the one with more information

        ONLY do one artifact per FHIR record and, provide:
        - id: The exact FHIR resource ID
        - title: Max 4 words describing the document type (e.g., "Chest CT Report", "Pathology Results", "Genetic Testing")
        - resourceType: The FHIR resource type (e.g., "DiagnosticReport", "DocumentReference")
        
        ONLY include records with meaningful narrative text written by healthcare providers. Skip simple lab values, vital signs, or medication lists without narrative content.
        
        SF Symbol icon examples:
        - heart.text.square.fill - For physical examinations
        - cross.fill - For emergency events
        - pills.fill - For medication changes
        - heart.fill - For cardiac events
        - lungs.fill - For respiratory issues
        - brain.head.profile - For neurological events
        - bandage.fill - For injuries or surgeries
        - allergens - For allergies
        - syringe - For immunizations or injections
        - stethoscope - For general medical visits
        - doc.text - For medical documents or reports
        - testtube.2 - For lab work/testing
        
        EXAMPLE OUTPUT:
        {
            "title": "Annual Physical Examination",
            "description": "Routine checkup with blood work and immunization updates completed.",
            "icon": "stethoscope",
            "artifacts": [
                {
                    "id": "DiagnosticReport/chest-xray-2024",
                    "title": "Chest X-Ray Report",
                    "resourceType": "DiagnosticReport"
                }
            ]
        }

        IMPORTANT: Include ONLY confirmed health events. Do not create fictional details.
        """
    }
    
    // MARK: - Detailed Summaries
    
    
    // MARK: - Individual Record Summaries
    
    /// Prompt for summarizing individual FHIR records
    static func fhirRecordSummaryPrompt(fhirJson: String) -> String {
        return """
        Summarize this FHIR health record in Markdown format using simple, everyday language that a non-medical person can understand.
        
        FHIR Record:
        \(fhirJson)
        
        Requirements:
        1. Use simple, everyday language that a non-medical person can understand
        2. Explain what this record represents and why it might be important
        3. Include key dates, values, and findings
        4. Report findings objectively without medical interpretation
        5. If there are medications, procedures, or diagnoses, explain what they are for
        6. Keep the summary concise but comprehensive (2-4 paragraphs)
        7. Do not include any personally identifiable information (names, addresses, phone numbers, etc.)
        8. Do not make ANY diagnostic statements
        9. Provide only the summary content - do not include conversational phrases like "Here is a summary" or "This record shows"
        10. Use basic markdown formatting with **bold text** for emphasis, *italic text* for measurements or subtle emphasis, and simple single-level bullet points with * for lists. Use newlines (\n) to separate paragraphs and improve readability. Avoid nested bullets or complex markdown structures.

        EXAMPLE OUTPUT:
        **Blood Pressure Measurement**
        
        This record documents a **blood pressure reading** taken during a routine medical visit. Blood pressure measures the force of blood against artery walls and is an important indicator of heart health.
        
        **Reading Results**
        The measurement showed *128/82 mmHg*. The first number (128) represents **systolic pressure** when the heart beats, and the second number (82) represents **diastolic pressure** when the heart rests between beats.
        
        **Clinical Context**
        This reading falls in the **elevated category** according to standard guidelines. The healthcare provider noted this should be monitored more closely and recommended lifestyle modifications including reducing sodium intake and increasing physical activity.
        """
    }
    
    // MARK: - Doctor Questions Generation
    
    /// Prompt for generating doctor questions based on FHIR records
    static func doctorQuestionsPrompt(
        date: String,
        fhirResourcesJson: String,
        timelineContext: String,
        existingQuestions: [String] = []
    ) -> String {
        return """
        Below are FHIR health records for a patient from \(date).
        
        Timeline Context: \(timelineContext)
        
        ================================================
        \(fhirResourcesJson)
        ================================================
        
        Your task is to generate 0-4 meaningful questions that a patient should ask their doctor about these health records during their next appointment.

        IMPORTANT: Only generate questions that would genuinely help the patient understand their condition or care. If the records are routine with all values within reference ranges or no actionable items, it's acceptable to return fewer questions or even no questions. Quality over quantity - avoid generic or filler questions.
        \(existingQuestions.isEmpty ? "" : """
        
        IMPORTANT: The following questions have already been generated. Do NOT repeat these questions:
        \(existingQuestions.map { "- \($0)" }.joined(separator: "\n"))
        
        Generate NEW questions that are different from the ones above.
        """)
        
        INSTRUCTIONS:
        1. Generate questions that are specific to the medical records provided
        2. Focus on questions that help the patient understand their health better
        3. Include questions about next steps, treatment options, and follow-up care
        4. Make questions clear and easy for patients to ask
        5. Categorize each question appropriately
        6. Prioritize questions based on medical importance
        7. Never include personally identifiable information
        8. Avoid questions that require the patient to self-diagnose
        
        QUESTION CATEGORIES:
        - "symptoms": Questions about symptoms, how the patient feels, or changes to monitor
        - "tests": Questions about test results, what they mean, or future testing needed
        - "treatment": Questions about current treatments, medications, or therapy options
        - "follow_up": Questions about next appointments, monitoring, or ongoing care
        - "lifestyle": Questions about diet, exercise, activities, or lifestyle modifications
        
        PRIORITY LEVELS:
        - "high": Critical questions about urgent concerns, safety, or important next steps
        - "medium": Important questions about understanding results or treatment plans
        - "low": General questions about lifestyle or preventive care
        
        EXAMPLE QUESTIONS:
        - "What do my cholesterol numbers mean and should I be concerned about them?" (category: "tests", priority: "medium", whyAsk: "Understanding your cholesterol levels helps you know your heart disease risk and what steps to take.")
        - "Are there any side effects I should watch for with my new medication?" (category: "treatment", priority: "high", whyAsk: "Knowing potential side effects helps you identify problems early and stay safe while taking your medication.")
        - "How often should I schedule follow-up appointments for this condition?" (category: "follow_up", priority: "medium", whyAsk: "Regular monitoring ensures your treatment is working and catches any changes in your condition early.")
        - "What dietary changes would you recommend based on my test results?" (category: "lifestyle", priority: "low", whyAsk: "Diet changes can improve your lab results and overall health without additional medications.")
        
        For each question, provide a "whyAsk" explanation in plain, patient-friendly language that explains the value and importance of asking that specific question.
        
        Generate questions that are directly relevant to the provided health records. Do not create generic health questions.
        """
    }
    
    // MARK: - Artifact Processing
    
    /// Prompt for processing FHIR artifacts to extract text and generate medical term annotations
    static func artifactProcessingPrompt(fhirJson: String, resourceId: String) -> String {
        return """
        Analyze this FHIR resource and extract the actual medical document content organized by sections with annotations.
        
        FHIR RESOURCE JSON:
        \(fhirJson)
        
        YOUR TASKS:
        1. EXTRACT SECTIONS: If the document has natural sections, extract them. If not, create one comprehensive section.
        2. GENERATE TITLE: Create a descriptive 2-4 word title for this document
        3. IDENTIFY TERMS: List medical terms that need layperson explanations
        
        SECTION EXTRACTION RULES:
        - Extract the ACTUAL text content from the document (clinically significant parts only)
        - If document has clear sections (e.g., "Findings", "Impression", "Procedure Details"), preserve them
        - If no clear sections, create one section with all clinically relevant content
        - Each section should have a descriptive title (e.g., "Findings", "Procedure Details", "Recommendations")
        - Content should be the actual text from the document, not summaries or rewrites
        - Focus only on clinically significant content - skip administrative details, headers, footers
        - Mark sections with critical findings/conclusions with isImportant: true
        - Handle base64 decoded attachment data if present in "_attachmentContent" field
        - Use newlines (\n) to separate paragraphs and improve readability
        - For lists, use terminal-style formatting with dashes and proper spacing (e.g., "- Item 1\n- Item 2")
        
        EXAMPLE OUTPUT (Multi-section document):
        {
          "title": "Pathology Report",
          "sections": [
            {
              "title": "Clinical History",
              "content": "Patient presented with abdominal pain and change in bowel habits. Colonoscopy revealed a mass in the sigmoid colon. Biopsy was performed for histologic evaluation.",
              "isImportant": false
            },
            {
              "title": "Pathologic Findings",
              "content": "The specimen shows invasive adenocarcinoma, moderately differentiated.\n\nMorphologic features:\n- Tumor measures 3.2 cm in greatest dimension\n- Invades through the muscularis propria\n- Extends into pericolonic adipose tissue\n- No lymphovascular invasion identified",
              "isImportant": true
            },
            {
              "title": "Final Diagnosis", 
              "content": "Sigmoid colon, segmental resection: Invasive adenocarcinoma, moderately differentiated, T3N0M0 staging. Margins are clear of carcinoma.",
              "isImportant": true
            }
          ],
          "medicalTerms": [
            {
              "term": "adenocarcinoma",
              "explanation": "A type of cancer that starts in the cells that line certain organs and produce mucus.",
              "category": "condition",
              "alternatives": ["adenocarcinoma", "carcinoma"]
            }
          ]
        }
        
        EXAMPLE OUTPUT (Single-section document):
        {
          "title": "Chest X-Ray Report",
          "sections": [
            {
              "title": "Radiologic Findings",
              "content": "Frontal and lateral chest radiographs show clear lung fields bilaterally. No focal consolidation, pneumothorax, or pleural effusion. Heart size is normal. Bony structures appear intact. No acute cardiopulmonary abnormality identified.",
              "isImportant": false
            }
          ],
          "medicalTerms": [
            {
              "term": "consolidation",
              "explanation": "An area of the lung that has filled with fluid or other material instead of air, often indicating pneumonia.",
              "category": "medical_term",
              "alternatives": ["consolidation", "infiltrate"]
            }
          ]
        }
        
        MEDICAL TERM IDENTIFICATION:
        - Target medical terminology that a layperson wouldn't understand
        - Provide 1-2 sentence simple explanations
        - Skip common words like "patient", "normal", "test"
        - Include alternative ways the term might appear
        
        CATEGORIES:
        Use these categories: medical_term, procedure, anatomy, measurement, condition, medication
        
        Extract the actual document text, organized logically by sections when present.
        """
    }
    
    // MARK: - Literacy Level Summaries
    
    /// Prompt for generating simple language summaries with structured events
    static func everydayLanguageSummaryPrompt(date: String, fhirResourcesJson: String) -> String {        
        return """
        Below are FHIR health records for a patient:
        ================================================
        \(fhirResourcesJson)
        ================================================
        Your task is to analyze these FHIR health records and create a summary using SIMPLE LANGUAGE that a non-medical person can easily understand

        INSTRUCTIONS:
        1. Never include any personally identifiable information (PII). Use passive tone and not a conversational tone (do not mention "you" or "the patient")
        2. Use simple, everyday language that anyone can understand. Avoid medical jargon completely. Use anologies if it helps with explaining hard concepts.
        3. Break down the information into multiple events if necessary but start with the most clinically significant events.
        3. No need to mention dates as the date is already shown to the user
        4. For each event, provide:
           - A **headline** (5-8 words) that captures the main point
           - A **subheadline** (10-12 words) that adds important context  
           - A **body** (text in markdown format) that describes a short paragraph on more details
        5. Use basic markdown formatting in the body (**bold** for emphasis, *italic* for measurements) and newlines (\n) to separate paragraphs
        6. Explain medical terms in simple language (e.g., "blood pressure" instead of "hypertension")
        7. NEVER interpret what results mean for health - only describe what was measured
        8. Use "in range", "above range", or "below range" instead of medical interpretations like "normal", "high", "low", "healthy", "concerning"

        EXAMPLE OUTPUT:
        {
          "events": [
            {
              "headline": "Blood Test Results Came Back",
              "subheadline": "Lab work measured different substances in your blood",
              "body": "You had **blood tests** done to measure different substances in your blood. The results show that your *cholesterol levels* are in the expected range for this test. Your *blood sugar* level was also within the reference range provided by the lab."
            },
            {
              "headline": "Doctor Visit and Health Check",
              "subheadline": "Physical examination and measurements were completed",
              "body": "You had a **complete physical exam** where various body systems were examined. Your *blood pressure* was measured at 120/80 mmHg, which is within the reference range. Other measurements and observations were recorded during the visit."
            }
          ]
        }

        Generate the structured summary now.
        """
    }
    
    /// Prompt for generating detailed summaries with structured events
    static func slightlyTechnicalSummaryPrompt(date: String, fhirResourcesJson: String) -> String {        
        return """
        Below are FHIR health records for a patient:
        ================================================
        \(fhirResourcesJson)
        ================================================
        Your task is to analyze these FHIR health records and create a summary using DETAILED language for someone with basic medical knowledge.

        INSTRUCTIONS:
        1. Never include any personally identifiable information (PII). Use passive voice.
        2. Use medical terms when appropriate, but explain them when necessary. Use analogies if needed.
        3. Include specific values and ranges where relevant
        3. No need to mention dates as the date is already shown to the user
        4. Break down the information into multiple events but start with the most clinically siginficant events.
        5. For each event, provide:
           - A **headline** (5-8 words) using appropriate medical terminology
           - A **subheadline** (10-12 words) that adds clinical context  
           - A **body** (longer text in markdown format) that describes the findings objectively

        6. Use basic markdown formatting (**bold** for conditions/procedures, *italic* for values) and newlines (\n) to separate paragraphs
        7. Include reference ranges and values where applicable
        8. Describe findings objectively without clinical interpretation
        9. Use "within reference range", "above reference range", or "below reference range" instead of "normal", "abnormal", "high", "low"

        EXAMPLE OUTPUT:
        {
          "events": [
            {
              "headline": "Comprehensive Metabolic Panel Results",
              "subheadline": "Laboratory values measured for metabolic function assessment",
              "body": "A **comprehensive metabolic panel** was performed to measure kidney function, liver function, and electrolyte levels. The results showed *glucose* at 95 mg/dL (reference range: 70-100 mg/dL), *creatinine* at 1.0 mg/dL (reference: 0.6-1.3 mg/dL), and *eGFR* >60. Liver enzymes including *ALT* and *AST* were within reference ranges."
            },
            {
              "headline": "Physical Examination Findings",
              "subheadline": "Cardiovascular and pulmonary systems were assessed",
              "body": "**Physical examination** was completed with vital signs recorded: *blood pressure* 122/78 mmHg, *heart rate* 72 bpm, and *respiratory rate* 16/min. **Cardiovascular examination** revealed regular rate and rhythm with no murmurs detected. **Pulmonary examination** showed clear lung fields bilaterally."
            }
          ]
        }

        Generate the structured summary now.
        """
    }
    
    /// Prompt for generating medical language summaries with structured events
    static func doctorLanguageSummaryPrompt(date: String, fhirResourcesJson: String) -> String {        
        return """
        Below are FHIR health records for a patient from the same date.
        ================================================
        \(fhirResourcesJson)
        ================================================
        Your task is to analyze these FHIR health records and create a terse clinical summary using MEDICAL TERMINOLOGY appropriate for healthcare professionals.

        INSTRUCTIONS:
        1. Never include any personally identifiable information (PII). Use passive voice.
        2. Use precise medical terminology and clinical language
        3. Include most important laboratory values, vital signs, and diagnostic findings with reference ranges
        4. No need to mention dates as the date is already shown to the user
        4. Break down the information into multiple clinical events starting with most signfiicant events (2-4 events typically).
        5. For each event, provide:
           - A **headline** (5-8 words) using medical terminology
           - A **subheadline** (10-12 words) with clinical context
           - A **body** (longer text in markdown format) with detailed objective findings

        6. Use basic markdown formatting (**bold** for diagnoses/procedures, *italic* for specific values) and newlines (\n) to separate paragraphs
        7. Include relevant clinical parameters and reference ranges
        8. Report findings objectively without diagnostic interpretation
        9. Use standard medical abbreviations where appropriate
        10. Use "within reference range", "above reference range", or "below reference range" for lab values
        11. Do not mention codes/values from FHIR record unless it makes sense to a clinicain.

        EXAMPLE OUTPUTS:
        
        Example 1 - Cardiovascular Assessment:
        {
          "events": [
            {
              "headline": "Cardiovascular Examination and Cardiac Biomarkers",
              "subheadline": "Complete cardiac assessment with troponin and BNP evaluation",
              "body": "**Cardiovascular examination** revealed regular cardiac rhythm with *HR 72 bpm*, *BP 138/88 mmHg* (above reference range: 120/80). **Auscultation** demonstrated *S1* and *S2* present without murmurs, gallops, or rubs. **JVP** at 6 cm H2O. **Peripheral edema** absent bilaterally. **Cardiac biomarkers**: *Troponin I* <0.01 ng/mL (reference: <0.04 ng/mL, within range), *BNP* 85 pg/mL (reference: <100 pg/mL, within range). **ECG** showed normal sinus rhythm, *PR interval* 160 ms, *QRS duration* 90 ms, no ST-T wave abnormalities."
            },
            {
              "headline": "Lipid Panel and Metabolic Assessment",
              "subheadline": "Comprehensive lipid profile with calculated cardiovascular risk markers",
              "body": "**Lipid panel** results: *Total cholesterol* 242 mg/dL (reference: <200 mg/dL, above range), *LDL-C* 158 mg/dL (reference: <100 mg/dL, above range), *HDL-C* 38 mg/dL (reference: >40 mg/dL, below range), *Triglycerides* 230 mg/dL (reference: <150 mg/dL, above range). **Non-HDL cholesterol** calculated at 204 mg/dL. **Apolipoprotein B* 125 mg/dL (reference: <90 mg/dL, above range). **hsCRP* 3.2 mg/L indicating moderate cardiovascular risk. Patient currently on **atorvastatin 40mg daily**, last dose adjustment 3 months prior."
            }
          ]
        }
        
        Example 2 - Diabetes Management Visit:
        {
          "events": [
            {
              "headline": "Glycemic Control and Diabetes Monitoring",
              "subheadline": "HbA1c assessment with continuous glucose monitoring data review",
              "body": "**Glycemic control** evaluation: *HbA1c* 8.2% (reference: <7.0% for diabetics, above target range), representing 3-month average glucose of ~189 mg/dL. **Fasting plasma glucose* 156 mg/dL (reference: 70-100 mg/dL, above range). **CGM data** review: Time in range (70-180 mg/dL) at 62%, time below range (<70 mg/dL) at 2%, time above range (>180 mg/dL) at 36%. **Glycemic variability* (CV) 34%. Current regimen: **metformin 1000mg BID**, **glargine insulin* 24 units qHS."
            },
            {
              "headline": "Diabetic Complication Screening Results",
              "subheadline": "Annual microvascular and macrovascular complication assessment completed",
              "body": "**Nephropathy screening**: *Urine albumin-creatinine ratio* 45 mg/g (reference: <30 mg/g, microalbuminuria range), *eGFR* 72 mL/min/1.73m² (CKD-EPI equation, Stage 2 CKD). **Retinopathy screening**: Dilated fundoscopic examination revealed mild non-proliferative diabetic retinopathy (NPDR) bilaterally. **Neuropathy assessment**: Monofilament testing intact at all sites, *vibration perception threshold* 15V (mild elevation). **Peripheral vascular assessment**: *ABI* 0.95 bilaterally (reference: 0.9-1.3, within range), pedal pulses 2+ bilaterally."
            }
          ]
        }

        Generate the structured summary now.
        """
    }
    
    // MARK: - Model Configuration
    
    /// Thinking budget configuration for all Gemini models
    struct ThinkingBudgetConfig {
        private static let userDefaults = UserDefaults.standard
        private static let defaultThinkingScale = 2 // Low thinking
        
        /// Thinking scale options (1-5)
        enum ThinkingScale: Int, CaseIterable {
            case minimal = 1
            case low = 2
            case moderate = 3
            case high = 4
            case maximum = 5
            
            var displayName: String {
                switch self {
                case .minimal: return "Minimal"
                case .low: return "Low"
                case .moderate: return "Moderate"
                case .high: return "High"
                case .maximum: return "Maximum"
                }
            }
            
            var description: String {
                switch self {
                case .minimal: return "Fastest responses"
                case .low: return "Quick responses"
                case .moderate: return "Balanced quality & speed"
                case .high: return "Higher quality responses"
                case .maximum: return "Best quality responses"
                }
            }
            
            var tokenBudget: Int {
                switch self {
                case .minimal: return 128
                case .low: return 512
                case .moderate: return 2048
                case .high: return 8192
                case .maximum: return 24576
                }
            }
        }
        
        /// Get the configured thinking scale (1-5)
        static var thinkingScale: ThinkingScale {
            let rawValue = userDefaults.object(forKey: "thinkingBudget.scale") as? Int ?? defaultThinkingScale
            return ThinkingScale(rawValue: rawValue) ?? .minimal
        }
        
        /// Set the thinking scale (1-5)
        static func setThinkingScale(_ scale: ThinkingScale) {
            userDefaults.set(scale.rawValue, forKey: "thinkingBudget.scale")
        }
        
        /// Get the token budget for the current scale
        static var modelThinkingBudget: Int {
            return thinkingScale.tokenBudget
        }
        
        static let defaultScale = ThinkingScale(rawValue: defaultThinkingScale) ?? .minimal
    }
    
    /// Model names for different types of AI operations - configurable via settings
    struct ModelNames {
        private static let userDefaults = UserDefaults.standard
        
        static var clusterTimeline: String {
            // Default: false (use flash for speed)
            let useProMode = userDefaults.object(forKey: "useProMode.clusterTimeline") as? Bool ?? false
            return useProMode ? "gemini-2.5-pro" : "gemini-2.5-flash"
        }
        
        static var clusterSummary: String {
            // Default: false (use flash for speed)
            let useProMode = userDefaults.object(forKey: "useProMode.clusterSummary") as? Bool ?? false
            return useProMode ? "gemini-2.5-pro" : "gemini-2.5-flash"
        }
        
        static var recordSummary: String {
            // Default: false (use flash for speed)
            let useProMode = userDefaults.object(forKey: "useProMode.recordSummary") as? Bool ?? false
            return useProMode ? "gemini-2.5-pro" : "gemini-2.5-flash"
        }
        
        static var doctorQuestions: String {
            // Default: false (use flash for speed)
            let useProMode = userDefaults.object(forKey: "useProMode.doctorQuestions") as? Bool ?? false
            return useProMode ? "gemini-2.5-pro" : "gemini-2.5-flash"
        }
        
        static var artifactProcessing: String {
            // Default: false (use flash for speed and cost efficiency)
            let useProMode = userDefaults.object(forKey: "useProMode.artifactProcessing") as? Bool ?? false
            return useProMode ? "gemini-2.5-pro" : "gemini-2.5-flash"
        }
    }
    
    // MARK: - Usage Descriptions
    
    /// Standard usage descriptions for tracking AI usage
    struct UsageDescriptions {
        static func clusterTimeline(date: String, eventCount: Int) -> String {
            return "Timeline cluster generation for \(date) (\(eventCount) events)"
        }
        
        static func clusterSummary(date: String, literacyLevel: String) -> String {
            return "Cluster summary generation for \(date) (\(literacyLevel) level)"
        }
        
        
        static func recordSummary(recordId: String) -> String {
            return "FHIR record summary for record \(recordId)"
        }
        
        static func doctorQuestions(date: String) -> String {
            return "Doctor questions generation for \(date)"
        }
        
        static func artifactProcessing(resourceId: String) -> String {
            return "Artifact text extraction and annotation for \(resourceId)"
        }
    }
} 
