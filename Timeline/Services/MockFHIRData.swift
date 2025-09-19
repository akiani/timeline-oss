// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

struct MockFHIRData {
    static let colonCancerResources: [String: Any] = [
        // Initial symptoms and presentation - October 15, 2023
        "symptom-encounter-1": [
            "resourceType": "Encounter", "id": "symptom-encounter-1", "status": "finished",
            "class": ["code": "AMB", "display": "Ambulatory"],
            "type": [["text": "Primary Care Visit - New Symptoms"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-10-15T10:00:00Z", "end": "2023-10-15T10:45:00Z"],
            "reasonCode": [["text": "Patient presents with a 3-month history of progressive abdominal pain, primarily located in the left lower quadrant, accompanied by significant changes in bowel habits. Reports stools have become progressively narrower ('pencil-thin'), with occasional dark, tarry appearance suggesting possible melena. Associated symptoms include increased bloating after meals, mild unintentional weight loss (approximately 8 pounds over 3 months), and fatigue. No fever, no blood per rectum noted by patient, though reports feeling 'something isn't right' with digestion. Family history significant for maternal grandfather with colon cancer at age 72."]],
            "diagnosis": [["condition": ["display": "Query colorectal malignancy - requires urgent evaluation"]]]
        ],
        "vital-signs-1": [
            "resourceType": "Observation", "id": "vital-signs-1", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"]], "text": "Heart Rate"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-15T10:00:00Z",
            "valueQuantity": ["value": 82, "unit": "beats/min", "system": "http://unitsofmeasure.org", "code": "/min"],
            "note": [["text": "Regular rate and rhythm, slightly elevated possibly due to anxiety"]]
        ],
        "vital-signs-2": [
            "resourceType": "Observation", "id": "vital-signs-2", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"]], "text": "Blood Pressure"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-15T10:00:00Z",
            "component": [
                ["code": ["coding": [["system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"]]], "valueQuantity": ["value": 142, "unit": "mmHg"]],
                ["code": ["coding": [["system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"]]], "valueQuantity": ["value": 88, "unit": "mmHg"]]
            ],
            "note": [["text": "Elevated blood pressure, likely stress-related given patient's anxiety about symptoms"]]
        ],
        "vital-signs-3": [
            "resourceType": "Observation", "id": "vital-signs-3", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "29463-7", "display": "Body weight"]], "text": "Body Weight"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-15T10:00:00Z",
            "valueQuantity": ["value": 168, "unit": "lbs", "system": "http://unitsofmeasure.org", "code": "[lb_av]"],
            "note": [["text": "Patient reports 8-pound unintentional weight loss over past 3 months (previous weight 176 lbs)"]]
        ],
        "vital-signs-4": [
            "resourceType": "Observation", "id": "vital-signs-4", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "8310-5", "display": "Body temperature"]], "text": "Temperature"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-15T10:00:00Z",
            "valueQuantity": ["value": 98.4, "unit": "degF", "system": "http://unitsofmeasure.org", "code": "[degF]"]
        ],
        "physical-exam-1": [
            "resourceType": "Observation", "id": "physical-exam-1", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "exam"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "10191-5", "display": "Physical examination"]], "text": "Abdominal Examination"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-15T10:00:00Z",
            "valueString": "Abdomen soft, mild distension noted. Tenderness to palpation in left lower quadrant, no guarding or rigidity. Bowel sounds present and normal. No masses palpated on superficial examination, though patient reports discomfort with deeper palpation in sigmoid region. No hepatosplenomegaly appreciated.",
            "note": [["text": "Findings consistent with patient's reported symptoms, warrants further investigation"]]
        ],
        "cbc-report-1": [
            "resourceType": "DiagnosticReport", "id": "cbc-report-1", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "LAB", "display": "Laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "58410-2", "display": "Complete blood count (CBC) panel"]], "text": "Complete Blood Count with Differential"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-10-15T16:30:00Z",
            "result": [
                ["reference": "Observation/hemoglobin-1", "display": "Hemoglobin 9.2 g/dL (Low) - Reference: 12.0-15.5"],
                ["reference": "Observation/hematocrit-1", "display": "Hematocrit 27.8% (Low) - Reference: 36-46%"],
                ["reference": "Observation/wbc-count-1", "display": "White Blood Cell Count 6.8 K/uL - Reference: 4.0-11.0"],
                ["reference": "Observation/platelet-1", "display": "Platelet Count 295 K/uL - Reference: 150-450"],
                ["reference": "Observation/mcv-1", "display": "Mean Corpuscular Volume 68 fL (Low) - Reference: 80-100"],
                ["reference": "Observation/mch-1", "display": "Mean Corpuscular Hemoglobin 22 pg (Low) - Reference: 27-33"],
                ["reference": "Observation/rdw-1", "display": "Red Cell Distribution Width 18.2% (High) - Reference: 11.5-14.5%"]
            ],
            "conclusion": "Findings consistent with iron deficiency anemia. Microcytic, hypochromic anemia with elevated RDW suggests chronic blood loss. Recommend iron studies and investigation for source of bleeding, particularly GI evaluation given patient's symptoms."
        ],
        "cmp-report-1": [
            "resourceType": "DiagnosticReport", "id": "cmp-report-1", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "LAB", "display": "Laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "24323-8", "display": "Comprehensive metabolic panel"]], "text": "Comprehensive Metabolic Panel"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-10-15T16:30:00Z",
            "result": [
                ["reference": "Observation/glucose-1", "display": "Glucose, fasting 94 mg/dL - Reference: 70-99"],
                ["reference": "Observation/bun-1", "display": "Blood Urea Nitrogen 22 mg/dL - Reference: 7-20"],
                ["reference": "Observation/creatinine-1", "display": "Creatinine 1.1 mg/dL - Reference: 0.7-1.3"],
                ["reference": "Observation/sodium-1", "display": "Sodium 138 mEq/L - Reference: 136-145"],
                ["reference": "Observation/potassium-1", "display": "Potassium 3.9 mEq/L - Reference: 3.5-5.1"],
                ["reference": "Observation/chloride-1", "display": "Chloride 102 mEq/L - Reference: 98-107"],
                ["reference": "Observation/albumin-1", "display": "Albumin 3.1 g/dL (Low) - Reference: 3.4-5.0"],
                ["reference": "Observation/protein-1", "display": "Total Protein 6.8 g/dL - Reference: 6.0-8.3"]
            ],
            "conclusion": "Mild hypoalbuminemia noted, which may be related to chronic disease process or nutritional status. Otherwise unremarkable metabolic panel."
        ],
        "iron-studies-1": [
            "resourceType": "DiagnosticReport", "id": "iron-studies-1", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "LAB", "display": "Laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "33747-0", "display": "Iron studies panel"]], "text": "Iron Studies Panel"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-10-15T16:30:00Z",
            "result": [
                ["reference": "Observation/iron-1", "display": "Iron, serum 42 mcg/dL (Low) - Reference: 60-170"],
                ["reference": "Observation/tibc-1", "display": "Total Iron Binding Capacity 485 mcg/dL (High) - Reference: 250-400"],
                ["reference": "Observation/ferritin-1", "display": "Ferritin 8 ng/mL (Low) - Reference: 15-150"],
                ["reference": "Observation/transferrin-sat-1", "display": "Transferrin Saturation 8.7% (Low) - Reference: 20-50%"]
            ],
            "conclusion": "Classic pattern of iron deficiency anemia with low serum iron, low ferritin, elevated TIBC, and low transferrin saturation. This degree of iron deficiency in an adult warrants investigation for gastrointestinal blood loss."
        ],
        "cea-tumor-marker-1": [
            "resourceType": "Observation", "id": "cea-tumor-marker-1", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "2039-6", "display": "Carcinoembryonic antigen"]], "text": "CEA (Carcinoembryonic Antigen)"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-15T16:30:00Z",
            "valueQuantity": ["value": 9.7, "unit": "ng/mL", "system": "http://unitsofmeasure.org", "code": "ng/mL"],
            "interpretation": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation", "code": "H", "display": "High"]]]],
            "referenceRange": [["low": ["value": 0, "unit": "ng/mL"], "high": ["value": 3.0, "unit": "ng/mL"], "text": "0-3.0 ng/mL"]],
            "note": [["text": "Significantly elevated CEA level. While not specific for colorectal cancer, this elevation in the setting of patient's symptoms and iron deficiency anemia raises concern for gastrointestinal malignancy and warrants urgent evaluation."]]
        ],
        "urgent-referral-1": [
            "resourceType": "ServiceRequest", "id": "urgent-referral-1", "status": "active",
            "intent": "order", "priority": "urgent",
            "code": ["coding": [["system": "http://snomed.info/sct", "code": "73761001", "display": "Colonoscopy"]], "text": "STAT Colonoscopy with Biopsy"],
            "subject": ["reference": "Patient/mock"], "authoredOn": "2023-10-15T11:15:00Z",
            "requester": ["display": "Dr. Sarah Johnson, MD, Family Medicine"],
            "performer": [["display": "Dr. Michael Chen, MD, Gastroenterology"]],
            "reasonCode": [["text": "Red flag symptoms highly suspicious for colorectal malignancy: iron deficiency anemia (Hgb 9.2), significantly elevated CEA (9.7), progressive change in bowel habits with pencil-thin stools, unintentional weight loss, and left lower quadrant pain. Urgent colonoscopy required for tissue diagnosis and staging if malignancy confirmed."]],
            "note": [["text": "Patient counseled on urgent nature of evaluation. Scheduled within 5 business days. Pre-procedural clearance and bowel prep instructions provided."]]
        ],

        // Colonoscopy and biopsy - October 20, 2023
        "colonoscopy-procedure": [
            "resourceType": "Procedure", "id": "colonoscopy-procedure", "status": "completed",
            "code": ["coding": [["system": "http://snomed.info/sct", "code": "73761001", "display": "Colonoscopy with biopsy"]], "text": "Diagnostic Colonoscopy with Tissue Sampling"],
            "subject": ["reference": "Patient/mock"], "performedDateTime": "2023-10-20T09:00:00Z",
            "performer": [["actor": ["display": "Dr. Michael Chen, MD, Gastroenterology"]]],
            "reasonCode": [["text": "Evaluation of iron deficiency anemia, elevated CEA, and concerning GI symptoms"]],
            "outcome": ["text": "Successful diagnostic colonoscopy completed to cecum. Large circumferential mass identified in sigmoid colon. Multiple biopsies obtained for histopathological analysis."],
            "note": [["text": "Procedure tolerated well under conscious sedation. Excellent bowel preparation. No immediate complications."]]
        ],
        "colonoscopy-report": [
            "resourceType": "DiagnosticReport", "id": "colonoscopy-report", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "EN", "display": "Endoscopy"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "10539-2", "display": "Colonoscopy report"]], "text": "Colonoscopy Procedure Report"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-10-20T11:30:00Z",
            "conclusion": "PROCEDURE: Diagnostic colonoscopy with biopsy\nINDICATION: Iron deficiency anemia, elevated CEA, change in bowel habits\nPREPARATION: Excellent (Boston Bowel Prep Scale 8/9)\nSEDATION: Conscious sedation with midazolam and fentanyl, monitored anesthesia care\nFINDINGS: The colonoscope was successfully advanced to the cecum with clear visualization of the appendiceal orifice and ileocecal valve. During withdrawal, a large circumferential, ulcerated, and friable mass was identified in the sigmoid colon, approximately 25 cm from the anal verge. The mass measured approximately 3.2 cm in length and was causing moderate luminal narrowing (approximately 60% stenosis). The lesion appeared to involve the full circumference of the bowel wall with raised, irregular edges and central ulceration with contact bleeding. No other polyps or masses were identified throughout the remainder of the colon. Multiple biopsies (8 samples) were obtained from the mass using cold biopsy forceps for histopathological analysis. Moderate amount of altered blood was noted proximal to the lesion.\nIMPRESSION: Large circumferential sigmoid colon mass highly suspicious for adenocarcinoma. Tissue samples sent for histopathological confirmation.\nRECOMMENDATIONS: 1) Await pathology results, 2) Staging CT abdomen/pelvis with IV contrast, 3) Surgical oncology consultation, 4) Multidisciplinary tumor board discussion pending final pathology.",
            "note": [["text": "Patient and family counseled on findings and next steps. High suspicion for malignancy based on appearance and clinical presentation."]]
        ],
        "colonoscopy-sedation": [
            "resourceType": "MedicationAdministration", "id": "colonoscopy-sedation", "status": "completed",
            "medicationCodeableConcept": ["text": "Midazolam 3mg IV + Fentanyl 100mcg IV"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-20T08:45:00Z",
            "performer": [["actor": ["display": "Dr. Jennifer Adams, MD, Anesthesiology"]]],
            "note": [["text": "Conscious sedation administered for colonoscopy. Patient monitored continuously with pulse oximetry, blood pressure, and cardiac monitoring. Procedure tolerated well with appropriate sedation level achieved."]]
        ],
        "post-procedure-vitals": [
            "resourceType": "Observation", "id": "post-procedure-vitals", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"]], "text": "Post-Procedure Heart Rate"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-20T11:00:00Z",
            "valueQuantity": ["value": 78, "unit": "beats/min", "system": "http://unitsofmeasure.org", "code": "/min"],
            "note": [["text": "Stable post-procedure vital signs. Patient recovered well from sedation."]]
        ],
        "bowel-prep-medication": [
            "resourceType": "MedicationRequest", "id": "bowel-prep-medication", "status": "completed",
            "intent": "order", "medicationCodeableConcept": ["text": "Polyethylene Glycol 3350 with Electrolytes (GoLYTELY)"],
            "subject": ["reference": "Patient/mock"], "authoredOn": "2023-10-18T15:00:00Z",
            "requester": ["display": "Dr. Michael Chen, MD, Gastroenterology"],
            "dosageInstruction": [["text": "Bowel preparation for colonoscopy: Begin clear liquid diet 24 hours before procedure. Evening before procedure: Drink first half of solution (2 liters) over 2 hours starting at 6 PM. Morning of procedure: Complete remaining solution (2 liters) 4-6 hours before scheduled procedure time. Continue clear liquids until 2 hours before procedure."]],
            "note": [["text": "Patient counseled on importance of complete bowel preparation for optimal visualization during procedure. Instructions provided for dietary restrictions and preparation timeline."]]
        ],

        // Pathology results and staging - October 25, 2023
        "biopsy-pathology-report": [
            "resourceType": "DiagnosticReport", "id": "biopsy-pathology-report", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "SP", "display": "Surgical Pathology"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "28642-3", "display": "Surgical pathology report"]], "text": "Colon Biopsy Pathology Report"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-10-25T14:00:00Z",
            "conclusion": "SPECIMEN: Sigmoid colon biopsies (8 pieces)\nCLINICAL HISTORY: 52-year-old patient with iron deficiency anemia, elevated CEA, and large sigmoid colon mass on colonoscopy\nGROSS DESCRIPTION: Received are 8 fragments of pink-tan tissue measuring 0.2 to 0.4 cm in greatest dimension. All tissue submitted in one cassette.\nMICROSCOPIC DESCRIPTION: Sections demonstrate fragments of colonic mucosa with areas of high-grade dysplasia and invasive adenocarcinoma. The malignant epithelium forms irregular glands with cribriform pattern and shows significant nuclear pleomorphism, increased mitotic activity, and loss of nuclear polarity. Areas of necrosis and desmoplastic stroma are present. The invasive component extends into the submucosa in the available tissue.\nIMMUNOHISTOCHEMISTRY: CDX2: Positive (intestinal differentiation), CK20: Positive, CK7: Negative, Supporting colonic primary\nFINAL DIAGNOSIS: Sigmoid colon biopsy: Invasive adenocarcinoma, moderately to poorly differentiated, arising from high-grade dysplasia (adenoma)\nCOMMENT: The findings confirm malignancy consistent with colorectal adenocarcinoma. Clinical correlation with staging imaging and multidisciplinary team discussion recommended for treatment planning.",
            "conclusionCode": [["coding": [["system": "http://snomed.info/sct", "code": "254637007", "display": "Primary malignant neoplasm of colon"]], "text": "Adenocarcinoma of sigmoid colon"]]
        ],
        "oncology-consultation-1": [
            "resourceType": "Encounter", "id": "oncology-consultation-1", "status": "finished",
            "class": ["code": "AMB", "display": "Ambulatory"],
            "type": [["text": "Initial Oncology Consultation"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-10-25T14:30:00Z", "end": "2023-10-25T15:30:00Z"],
            "participant": [["individual": ["display": "Dr. Evelyn Davis, MD, Medical Oncology"]]],
            "reasonCode": [["text": "New diagnosis of sigmoid colon adenocarcinoma confirmed on biopsy. Discussion of pathology results, staging workup requirements, and treatment planning. Patient and family counseled on diagnosis and prognosis. Staging CT scan ordered and surgical consultation arranged. Discussion of multidisciplinary approach including surgery, potential adjuvant chemotherapy, and follow-up surveillance. Patient expressed understanding of diagnosis and agrees with proposed treatment plan."]],
            "note": [["text": "Patient taking diagnosis well, good family support system. Baseline performance status excellent (ECOG 0). No significant comorbidities that would preclude standard treatment."]]
        ],
        "staging-ct-scan": [
            "resourceType": "ImagingStudy", "id": "staging-ct-scan", "status": "available",
            "modality": [["system": "http://dicom.nema.org/resources/ontology/DCM", "code": "CT", "display": "Computed Tomography"]],
            "subject": ["reference": "Patient/mock"], "started": "2023-10-22T10:00:00Z",
            "procedureCode": [["coding": [["system": "http://loinc.org", "code": "75622-1", "display": "CT Abdomen and Pelvis with contrast"]], "text": "Staging CT Abdomen/Pelvis with IV Contrast"]],
            "description": "Pre-contrast, arterial phase, and portal venous phase imaging of the abdomen and pelvis performed following administration of 150mL IV contrast (Omnipaque 350). Circumferential wall thickening identified in sigmoid colon with associated fat stranding and multiple enlarged mesenteric lymph nodes. Detailed evaluation for metastatic disease."
        ],
        "staging-ct-detailed-report": [
            "resourceType": "DiagnosticReport", "id": "staging-ct-detailed-report", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "RAD", "display": "Radiology"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "75622-1", "display": "CT Abdomen and Pelvis with contrast"]], "text": "Staging CT Abdomen and Pelvis"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-10-22T16:30:00Z",
            "conclusion": "TECHNIQUE: Multidetector helical CT of the abdomen and pelvis was performed following administration of 150 mL of IV contrast material (Omnipaque 350). Pre-contrast, arterial phase (25 seconds), and portal venous phase (70 seconds) images were obtained from the diaphragm to the pubic symphysis with 2.5mm slice thickness.\n\nFINDINGS:\nPRIMARY TUMOR: There is circumferential wall thickening involving the sigmoid colon extending over approximately 3.8 cm in length. The wall thickness measures up to 1.2 cm with associated pericolonic fat stranding extending 8-10 mm from the bowel wall. The mass appears to abut but not clearly invade the adjacent mesenteric fat planes. No definite serosal involvement is identified.\n\nLYMPH NODES: Multiple enlarged mesenteric lymph nodes are identified in the sigmoid mesentery, with the largest measuring 1.1 cm in short axis diameter. At least 4-5 lymph nodes exceed 8mm in short axis, consistent with metastatic involvement.\n\nDISTANT METASTASES: \n- Liver: No focal hepatic lesions identified. Normal liver parenchyma enhancement pattern.\n- Lungs (included lung bases): No pulmonary nodules or masses identified.\n- Peritoneum: No ascites or peritoneal nodularity.\n- Bones (visualized): No suspicious lytic or blastic lesions.\n\nOTHER FINDINGS: Mild diverticulosis of the descending colon without inflammation. Small bilateral renal cysts, likely benign. Prostate gland appears normal in size.\n\nIMPRESSION:\n1. Sigmoid colon mass with circumferential wall thickening and pericolonic fat stranding, consistent with primary colonic malignancy (T3 lesion based on imaging)\n2. Multiple enlarged mesenteric lymph nodes highly suspicious for nodal metastases (N1-2 disease)\n3. No evidence of distant metastatic disease (M0)\n4. Preliminary staging: cT3N1-2M0 (Clinical Stage III)\n\nRECOMMENDATIONS: Surgical resection recommended with oncologic principles. Consider neoadjuvant versus adjuvant chemotherapy discussion at multidisciplinary tumor board.",
            "note": [["text": "Results discussed with referring oncologist. Findings consistent with locally advanced but resectable colon cancer without distant metastases."]]
        ],
        "cea-post-biopsy": [
            "resourceType": "Observation", "id": "cea-post-biopsy", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "2039-6", "display": "Carcinoembryonic antigen"]], "text": "CEA (Post-biopsy)"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-10-22T08:00:00Z",
            "valueQuantity": ["value": 14.2, "unit": "ng/mL", "system": "http://unitsofmeasure.org", "code": "ng/mL"],
            "interpretation": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation", "code": "H", "display": "High"]]]],
            "referenceRange": [["low": ["value": 0, "unit": "ng/mL"], "high": ["value": 3.0, "unit": "ng/mL"], "text": "0-3.0 ng/mL"]],
            "note": [["text": "Further elevation in CEA level compared to initial value of 9.7 ng/mL, consistent with progression of malignancy. Will serve as baseline tumor marker for monitoring treatment response and surveillance."]]
        ],

        // Surgical planning and pre-operative workup - November 10, 2023  
        "surgical-consultation": [
            "resourceType": "Encounter", "id": "surgical-consultation", "status": "finished",
            "class": ["code": "AMB", "display": "Ambulatory"],
            "type": [["text": "Surgical Oncology Consultation"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-11-10T14:00:00Z", "end": "2023-11-10T15:15:00Z"],
            "participant": [["individual": ["display": "Dr. Robert Martinez, MD, Colorectal Surgery"]]],
            "reasonCode": [["text": "Comprehensive surgical evaluation for newly diagnosed sigmoid colon adenocarcinoma, cT3N1-2M0. Discussion of surgical options, risks, and benefits of laparoscopic versus open approach. Patient is an excellent surgical candidate with no significant comorbidities. Recommendation for laparoscopic sigmoid colectomy with en bloc lymph node dissection following oncologic principles. Detailed discussion of operative risks including bleeding, infection, anastomotic leak (2-5% risk), injury to adjacent organs, conversion to open procedure if needed, and need for temporary or permanent colostomy (low risk with primary anastomosis planned). Patient and family demonstrated excellent understanding of procedure and risks. Informed consent obtained. Surgery scheduled within 10 days to minimize tumor progression."]],
            "note": [["text": "Patient expressed confidence in surgical team and treatment plan. Family very supportive. Pre-operative medical clearance arranged."]]
        ],
        "preop-medical-clearance": [
            "resourceType": "Encounter", "id": "preop-medical-clearance", "status": "finished",
            "class": ["code": "AMB", "display": "Ambulatory"],
            "type": [["text": "Pre-operative Medical Clearance"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-11-15T09:00:00Z", "end": "2023-11-15T09:45:00Z"],
            "participant": [["individual": ["display": "Dr. Sarah Johnson, MD, Family Medicine"]]],
            "reasonCode": [["text": "Pre-operative medical assessment for upcoming sigmoid colectomy. Review of systems negative for cardiac, pulmonary, or other systemic symptoms. Physical examination unremarkable except for known abdominal findings. Patient has excellent functional capacity, able to climb 2 flights of stairs without symptoms. No history of cardiovascular disease, diabetes, or pulmonary disease. Cleared for surgery with ASA Physical Status Class II (mild systemic disease). Recommended to continue all home medications except hold any blood thinners if applicable."]],
            "note": [["text": "Excellent surgical candidate with minimal perioperative risk. All systems optimized for surgery."]]
        ],
        "preop-laboratory-panel": [
            "resourceType": "DiagnosticReport", "id": "preop-laboratory-panel", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "LAB", "display": "Laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "24356-8", "display": "Urinalysis complete"]], "text": "Pre-operative Laboratory Panel"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-11-15T12:00:00Z",
            "result": [
                ["reference": "Observation/preop-cbc", "display": "CBC: Hemoglobin 10.8 g/dL (improved with iron supplementation)"],
                ["reference": "Observation/preop-platelets", "display": "Platelet Count 335 K/uL - Normal"],
                ["reference": "Observation/preop-pt-inr", "display": "PT/INR: 12.2 seconds, INR 1.0 - Normal coagulation"],
                ["reference": "Observation/preop-ptt", "display": "Partial Thromboplastin Time 28.5 seconds - Normal"],
                ["reference": "Observation/preop-cmp", "display": "Comprehensive Metabolic Panel: All values within normal limits"],
                ["reference": "Observation/preop-urinalysis", "display": "Urinalysis: Clear, no proteinuria, no signs of infection"]
            ],
            "conclusion": "All pre-operative laboratory values within acceptable limits for surgery. Hemoglobin improved with iron supplementation. Normal coagulation studies. Cleared from laboratory standpoint."
        ],
        "preop-cardiac-clearance": [
            "resourceType": "DiagnosticReport", "id": "preop-cardiac-clearance", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "CG", "display": "Cardiology"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "11524-6", "display": "EKG study"]], "text": "Pre-operative Electrocardiogram"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-11-15T11:30:00Z",
            "conclusion": "INTERPRETATION: Normal sinus rhythm at 68 bpm. Normal PR interval (160 ms), normal QRS duration (88 ms), normal QTc interval (420 ms). No acute ST-segment or T-wave abnormalities. No evidence of prior myocardial infarction. Normal axis. Overall normal EKG. CLEARED FOR SURGERY.\n\nCLINICAL CORRELATION: EKG findings normal for age. No contraindications to general anesthesia from cardiac standpoint.",
            "note": [["text": "Baseline EKG normal, cleared for anesthesia and surgery without further cardiac evaluation needed."]]
        ],
        "anesthesia-preop-evaluation": [
            "resourceType": "Encounter", "id": "anesthesia-preop-evaluation", "status": "finished",
            "class": ["code": "AMB", "display": "Ambulatory"],
            "type": [["text": "Anesthesiology Pre-operative Assessment"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-11-20T06:30:00Z", "end": "2023-11-20T07:15:00Z"],
            "participant": [["individual": ["display": "Dr. Jennifer Adams, MD, Anesthesiology"]]],
            "reasonCode": [["text": "Pre-operative anesthesia assessment for laparoscopic sigmoid colectomy. Airway examination: Mallampati Class I, good mouth opening, normal neck mobility, no anticipated difficult intubation. Review of systems negative for sleep apnea, reflux disease, or difficult intubation history. Vital signs stable. Physical examination unremarkable. ASA Physical Status Class II assigned. Anesthetic plan: General anesthesia with endotracheal intubation, balanced technique with sevoflurane maintenance and appropriate muscle relaxation. Regional anesthesia (TAP blocks) planned for post-operative pain management. Patient counseled on anesthetic risks and post-operative pain management strategy."]],
            "note": [["text": "Standard anesthetic risk discussed. Patient understanding confirmed. Consent for anesthesia obtained."]]
        ],

        // Surgery and immediate post-operative period - November 20, 2023
        "sigmoid-colectomy-procedure": [
            "resourceType": "Procedure", "id": "sigmoid-colectomy-procedure", "status": "completed",
            "code": ["coding": [["system": "http://snomed.info/sct", "code": "43099000", "display": "Sigmoid colectomy"]], "text": "Laparoscopic Sigmoid Colectomy with Primary Anastomosis"],
            "subject": ["reference": "Patient/mock"], "performedDateTime": "2023-11-20T08:30:00Z",
            "performer": [["actor": ["display": "Dr. Robert Martinez, MD, Colorectal Surgery"]]],
            "reasonCode": [["text": "Sigmoid colon adenocarcinoma, cT3N1M0"]],
            "outcome": ["text": "Successful laparoscopic sigmoid colectomy with en bloc mesenteric lymph node dissection completed following oncologic principles. Primary colorectal anastomosis performed with circular stapler. Estimated blood loss 180mL. No intraoperative complications. Specimen margins grossly negative. 18cm resection specimen with adequate proximal and distal margins."],
            "note": [["text": "Procedure completed entirely laparoscopically without need for conversion to open technique. Patient tolerated procedure well."]]
        ],
        "detailed-operative-note": [
            "resourceType": "DocumentReference", "id": "detailed-operative-note", "status": "current",
            "docStatus": "final", 
            "type": ["coding": [["system": "http://loinc.org", "code": "11504-8", "display": "Surgical operation note"]], "text": "Operative Report"],
            "subject": ["reference": "Patient/mock"], 
            "date": "2023-11-20T12:30:00Z",
            "author": [["display": "Dr. Robert Martinez, MD, Colorectal Surgery"]],
            "content": [[
                "attachment": [
                    "contentType": "text/plain",
                    "data": "OPERATIVE REPORT\n\nDATE OF SURGERY: November 20, 2023\nSURGEON: Dr. Robert Martinez, MD\nASSISTANT: Dr. Sarah Kim, MD\nANESTHESIA: Dr. Jennifer Adams, MD\n\nPREOPERATIVE DIAGNOSIS: Sigmoid colon adenocarcinoma, cT3N1M0\nPOSTOPERATIVE DIAGNOSIS: Same\nPROCEDURE: Laparoscopic sigmoid colectomy with en bloc mesenteric lymph node dissection and primary colorectal anastomosis\n\nINDICATION: 52-year-old patient with biopsy-proven sigmoid adenocarcinoma and staging consistent with T3N1M0 disease requiring oncologic resection.\n\nDESCRIPTION OF PROCEDURE:\nThe patient was positioned supine and underwent general endotracheal anesthesia. Sequential compression devices and appropriate monitoring were applied. The abdomen was prepped and draped in sterile fashion.\n\nA 12mm Hasson trocar was placed at the umbilicus and CO2 insufflation established to 15mmHg. Diagnostic laparoscopy revealed no evidence of carcinomatosis or liver metastases. The sigmoid tumor was readily identified with surrounding inflammatory changes but no gross serosal involvement.\n\nAdditional 5mm trocars were placed in the left lower quadrant, left upper quadrant, right lower quadrant, and suprapubic region under direct visualization. The patient was positioned in steep Trendelenburg with left side up.\n\nMobilization began with division of the lateral peritoneal attachments along the white line of Toldt from the splenic flexure to the rectosigmoid junction. The ureter was identified and protected throughout. The sigmoid and descending colon were mobilized medially.\n\nThe inferior mesenteric vessels were identified at the aortic bifurcation. The inferior mesenteric artery was divided at its origin using a vascular stapler after confirming adequate collateral circulation. The inferior mesenteric vein was divided at the lower border of the pancreas.\n\nHigh ligation was performed to ensure adequate lymph node harvest. The mesentery was divided using energy device with careful attention to preserve blood supply to the anastomotic ends.\n\nThe rectum was mobilized to the pelvic floor with division of the lateral ligaments. Adequate distal margin was confirmed (>5cm from tumor).\n\nA Pfannenstiel incision was made for specimen extraction. The sigmoid colon was divided proximally at the mid-descending colon and distally in the upper rectum using linear staplers. The specimen was extracted in a protective bag.\n\nA circular end-to-end anastomosis was performed using a 29mm circular stapler introduced transanally. Integrity was confirmed with air insufflation test - no leak identified. \n\nThe pelvis was irrigated and hemostasis confirmed. A JP drain was placed in the pelvis. Trocars were removed under direct vision and fascial defects >10mm were closed. The skin was closed with skin adhesive.\n\nSPECIMEN: 18cm segment of sigmoid colon containing a 3.8cm circumferential tumor with attached mesentery containing multiple lymph nodes.\n\nESTIMATED BLOOD LOSS: 180mL\nCOMPLICATIONS: None\nCONDITION: Stable, extubated, to PACU\n\nPOSTOPERATIVE PLAN:\n1. NPO until return of bowel function\n2. Foley catheter management\n3. Pain control with multimodal approach\n4. Early mobilization\n5. DVT prophylaxis\n6. JP drain monitoring\n7. Pathology follow-up for final staging\n8. Oncology follow-up for adjuvant therapy discussion"
                ]
            ]]
        ],
        "immediate-postop-vitals": [
            "resourceType": "Observation", "id": "immediate-postop-vitals", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"]], "text": "Post-operative Heart Rate"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-11-20T13:00:00Z",
            "valueQuantity": ["value": 85, "unit": "beats/min", "system": "http://unitsofmeasure.org", "code": "/min"],
            "note": [["text": "Immediate post-operative vital signs stable. Patient awake and comfortable in PACU."]]
        ],
        "postop-pain-management": [
            "resourceType": "MedicationRequest", "id": "postop-pain-management", "status": "active",
            "intent": "order", 
            "medicationCodeableConcept": ["text": "Multimodal Pain Management Protocol"],
            "subject": ["reference": "Patient/mock"], 
            "authoredOn": "2023-11-20T14:00:00Z",
            "requester": ["display": "Dr. Robert Martinez, MD, Colorectal Surgery"],
            "dosageInstruction": [[
                "text": "Post-operative pain management: 1) Acetaminophen 1000mg PO q6h scheduled, 2) Ibuprofen 600mg PO q6h scheduled (if no contraindications), 3) Oxycodone 5-10mg PO q4h PRN severe pain, 4) Ondansetron 4mg IV/PO q6h PRN nausea. Goal to minimize opioid use with multimodal approach."
            ]],
            "note": [["text": "Multimodal approach to optimize pain control while minimizing side effects and promoting early recovery."]]
        ],

        // Post-operative day 1 - November 21, 2023
        "postop-day1-rounds": [
            "resourceType": "Encounter", "id": "postop-day1-rounds", "status": "finished",
            "class": ["code": "IMP", "display": "Inpatient"],
            "type": [["text": "Post-operative Day 1 Surgical Rounds"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-11-21T07:00:00Z", "end": "2023-11-21T07:30:00Z"],
            "participant": [["individual": ["display": "Dr. Robert Martinez, MD, Colorectal Surgery"]]],
            "reasonCode": [["text": "Post-operative day 1 assessment following laparoscopic sigmoid colectomy. Patient reports minimal incisional pain (3/10), well-controlled with multimodal pain regimen. No nausea or vomiting overnight. Passing flatus, which is encouraging for return of bowel function. Tolerating clear liquids well. Ambulated to chair yesterday evening and took several walks with physical therapy. JP drain output 45mL serosanguineous fluid overnight, appropriate amount and character. Foley catheter draining clear yellow urine. Incision sites appear clean and dry without erythema or drainage. Plan to advance diet to full liquids today and remove Foley catheter if patient continues to progress well."]],
            "note": [["text": "Excellent early recovery. Patient motivated and participating well in post-operative care plan."]]
        ],
        "postop-lab-day1": [
            "resourceType": "DiagnosticReport", "id": "postop-lab-day1", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "LAB", "display": "Laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "58410-2", "display": "Complete blood count (CBC) panel"]], "text": "Post-operative Day 1 Laboratory"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-11-21T06:00:00Z",
            "result": [
                ["reference": "Observation/postop-hgb-day1", "display": "Hemoglobin 9.8 g/dL (appropriate for post-operative state)"],
                ["reference": "Observation/postop-wbc-day1", "display": "White Blood Cell Count 12.5 K/uL (expected post-operative elevation)"],
                ["reference": "Observation/postop-platelets-day1", "display": "Platelet Count 285 K/uL (stable)"]
            ],
            "conclusion": "Post-operative laboratory values appropriate for POD#1. Hemoglobin stable, no evidence of ongoing bleeding. WBC elevation consistent with normal post-operative inflammatory response."
        ],

        // Final surgical pathology - November 25, 2023
        "final-surgical-pathology": [
            "resourceType": "DiagnosticReport", "id": "final-surgical-pathology", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "SP", "display": "Surgical Pathology"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "28644-9", "display": "Surgical pathology cancer summary"]], "text": "Final Surgical Pathology Report - Sigmoid Colectomy"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-11-25T16:00:00Z",
            "conclusion": "FINAL SURGICAL PATHOLOGY REPORT\n\nSPECIMEN: Sigmoid colon resection with regional lymph nodes\nCLINICAL HISTORY: Sigmoid colon adenocarcinoma\n\nGROSS DESCRIPTION: The specimen consists of a segment of sigmoid colon measuring 18.0 cm in length with attached mesentery. The serosal surface is unremarkable except for a 4.0 x 3.5 cm area of puckering and slight discoloration overlying the tumor. Upon opening, there is a circumferential, ulcerated tumor measuring 3.8 x 3.2 x 1.2 cm located 8.5 cm from the distal surgical margin and 6.7 cm from the proximal margin. The tumor extends through the full thickness of the bowel wall with irregular, raised edges and central ulceration. The cut surface shows a firm, white-tan tumor with areas of necrosis. Multiple lymph nodes ranging from 0.3 to 1.5 cm are identified within the mesenteric fat.\n\nMICROSCOPIC DESCRIPTION: Sections of the tumor demonstrate moderately differentiated invasive adenocarcinoma arising from areas of high-grade dysplasia (adenomatous epithelium). The malignant glands show moderate nuclear pleomorphism, increased mitotic activity (8-10 mitoses per 10 high-power fields), and areas of cribriform architecture. The tumor invades through the muscularis propria and extends into the pericolonic adipose tissue but does not reach the serosal surface. Lymphovascular invasion is present in multiple foci. Perineural invasion is not identified. The tumor does not involve the proximal or distal surgical margins.\n\nLYMPH NODES: Twenty-two (22) lymph nodes are identified, three (3) of which contain metastatic adenocarcinoma. The largest metastatic deposit measures 0.8 cm and shows extension beyond the lymph node capsule (extranodal extension present).\n\nIMMUNOHISTOCHEMISTRY: \nMLH1: Retained nuclear expression\nMSH2: Retained nuclear expression  \nMSH6: Retained nuclear expression\nPMS2: Retained nuclear expression\nInterpretation: Intact mismatch repair protein expression, consistent with microsatellite stable (MSS) tumor\n\nFINAL DIAGNOSIS:\n1. Sigmoid colon: Invasive adenocarcinoma, moderately differentiated\n   - Tumor size: 3.8 cm (greatest dimension)\n   - Depth of invasion: pT3 (tumor invades through muscularis propria into pericolonic adipose tissue)\n   - Lymph nodes: pN1b (2-3 positive regional lymph nodes) - 3 of 22 nodes positive\n   - Distant metastases: pM0 (no distant metastases identified)\n   - Margins: Negative (proximal margin 6.7 cm, distal margin 8.5 cm)\n   - Lymphovascular invasion: Present\n   - Perineural invasion: Absent\n   - Microsatellite status: Stable (MSS)\n\nPATHOLOGIC STAGE (AJCC 8th Edition): Stage IIIA (pT3N1bM0)\n\nCOMMENT: The findings indicate moderately differentiated adenocarcinoma of the sigmoid colon with regional lymph node metastases. The presence of lymphovascular invasion and nodal involvement indicates higher risk disease that would benefit from adjuvant systemic therapy. Microsatellite stable status suggests standard fluoropyrimidine-based adjuvant chemotherapy would be appropriate. Recommend oncology consultation for adjuvant therapy planning.",
            "conclusionCode": [["coding": [["system": "http://snomed.info/sct", "code": "254637007", "display": "Primary malignant neoplasm of colon"]], "text": "Adenocarcinoma of sigmoid colon, Stage IIIA"]]
        ],

        // Discharge and early follow-up - November 23, 2023
        "hospital-discharge": [
            "resourceType": "Encounter", "id": "hospital-discharge", "status": "finished",
            "class": ["code": "IMP", "display": "Inpatient"],
            "type": [["text": "Hospital Discharge"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-11-20T08:30:00Z", "end": "2023-11-23T11:00:00Z"],
            "reasonCode": [["text": "Patient successfully recovering from laparoscopic sigmoid colectomy on post-operative day 3. Bowel function has returned with passage of flatus and small bowel movement. Tolerating regular diet without nausea or vomiting. Pain well-controlled with oral medications. Incisions healing well without signs of infection. JP drain removed this morning after output decreased to <30mL/day. Patient ambulating independently and cleared by physical therapy for discharge home. Comprehensive discharge education provided including activity restrictions, dietary guidelines, wound care instructions, and symptoms requiring immediate medical attention."]],
            "hospitalization": [
                "dischargeDisposition": ["coding": [["system": "http://terminology.hl7.org/CodeSystem/discharge-disposition", "code": "home", "display": "Home"]], "text": "Discharged home"]
            ]
        ],
        "discharge-medications": [
            "resourceType": "MedicationRequest", "id": "discharge-medications", "status": "active",
            "intent": "order",
            "medicationCodeableConcept": ["text": "Post-operative Discharge Medications"],
            "subject": ["reference": "Patient/mock"], 
            "authoredOn": "2023-11-23T10:30:00Z",
            "requester": ["display": "Dr. Robert Martinez, MD, Colorectal Surgery"],
            "dosageInstruction": [[
                "text": "Discharge medications: 1) Acetaminophen 650mg PO every 6 hours as needed for pain (max 3000mg/day), 2) Ibuprofen 400mg PO every 6 hours as needed for pain (take with food), 3) Docusate sodium 100mg PO twice daily as needed for constipation, 4) Simethicone 40mg PO four times daily as needed for gas bloating. Avoid lifting >10 pounds for 6 weeks. Return to surgeon if fever >101.5°F, severe abdominal pain, inability to tolerate food/fluids, or concerning incision changes."
            ]],
            "note": [["text": "Patient counseled on proper use of medications and activity restrictions. Understands when to seek immediate medical care."]]
        ],

        // Post-operative follow-up and chemotherapy planning - December 5, 2023
        "postop-surgical-followup": [
            "resourceType": "Encounter", "id": "postop-surgical-followup", "status": "finished",
            "class": ["code": "AMB", "display": "Ambulatory"],
            "type": [["text": "Post-operative Surgical Follow-up Visit"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-12-05T10:00:00Z", "end": "2023-12-05T10:45:00Z"],
            "participant": [["individual": ["display": "Dr. Robert Martinez, MD, Colorectal Surgery"]]],
            "reasonCode": [["text": "Two-week post-operative follow-up visit following laparoscopic sigmoid colectomy. Patient reports excellent recovery with minimal pain and return to most normal activities. Bowel movements regular and formed, no diarrhea or constipation. Incisions healed completely with good cosmetic result, all skin staples previously removed. No concerning symptoms including fever, severe pain, or signs of infection. Review of final pathology results: pT3N1bM0 adenocarcinoma, Stage IIIA with 3 of 22 lymph nodes positive. Discussed need for adjuvant chemotherapy given node-positive disease. Patient ready to proceed with oncology consultation for adjuvant treatment planning. Cleared for normal activities with continued lifting restriction <25 pounds for another month."]],
            "note": [["text": "Excellent surgical recovery. Patient well-prepared for next phase of treatment with adjuvant chemotherapy."]]
        ],
        "postop-cea-followup": [
            "resourceType": "Observation", "id": "postop-cea-followup", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "2039-6", "display": "Carcinoembryonic antigen"]], "text": "CEA (Post-operative Baseline)"],
            "subject": ["reference": "Patient/mock"], "effectiveDateTime": "2023-12-05T08:00:00Z",
            "valueQuantity": ["value": 2.8, "unit": "ng/mL", "system": "http://unitsofmeasure.org", "code": "ng/mL"],
            "interpretation": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation", "code": "N", "display": "Normal"]]]],
            "referenceRange": [["low": ["value": 0, "unit": "ng/mL"], "high": ["value": 3.0, "unit": "ng/mL"], "text": "0-3.0 ng/mL"]],
            "note": [["text": "Excellent response to surgery with normalization of CEA level from pre-operative high of 14.2 ng/mL. This will serve as new baseline for monitoring during and after adjuvant chemotherapy."]]
        ],

        // Adjuvant chemotherapy initiation - December 15, 2023
        "oncology-adjuvant-consultation": [
            "resourceType": "Encounter", "id": "oncology-adjuvant-consultation", "status": "finished",
            "class": ["code": "AMB", "display": "Ambulatory"],
            "type": [["text": "Adjuvant Chemotherapy Planning Consultation"]],
            "subject": ["reference": "Patient/mock"],
            "period": ["start": "2023-12-15T14:00:00Z", "end": "2023-12-15T15:15:00Z"],
            "participant": [["individual": ["display": "Dr. Evelyn Davis, MD, Medical Oncology"]]],
            "reasonCode": [["text": "Comprehensive discussion of adjuvant chemotherapy for Stage IIIA (pT3N1bM0) colon adenocarcinoma following successful surgical resection. Reviewed pathology showing 3 of 22 nodes positive with microsatellite stable tumor. Based on NCCN guidelines and clinical trial data (MOSAIC, C-07), recommended FOLFOX regimen (5-FU, leucovorin, oxaliplatin) for 6 months (12 cycles) given clear survival benefit in node-positive disease. Discussed treatment schedule, expected side effects including neuropathy, nausea, diarrhea, fatigue, and rare serious complications. Patient demonstrates excellent performance status (ECOG 0) and strong social support system. Reviewed importance of completing full course of therapy for optimal outcomes. Patient expressed understanding and agreement to proceed with treatment. Pre-treatment laboratory studies and port placement arranged."]],
            "note": [["text": "Patient well-informed about treatment plan and committed to completing adjuvant therapy. Baseline studies show excellent organ function for chemotherapy."]]
        ],
        "chemo-baseline-labs": [
            "resourceType": "DiagnosticReport", "id": "chemo-baseline-labs", "status": "final",
            "category": [["coding": [["system": "http://terminology.hl7.org/CodeSystem/v2-0074", "code": "LAB", "display": "Laboratory"]]]],
            "code": ["coding": [["system": "http://loinc.org", "code": "58410-2", "display": "Complete blood count (CBC) panel"]], "text": "Pre-chemotherapy Baseline Laboratory Studies"],
            "subject": ["reference": "Patient/mock"], "issued": "2023-12-15T08:00:00Z",
            "result": [
                ["reference": "Observation/chemo-baseline-hgb", "display": "Hemoglobin 12.2 g/dL (excellent recovery)"],
                ["reference": "Observation/chemo-baseline-wbc", "display": "White Blood Cell Count 7.2 K/uL (normal)"],
                ["reference": "Observation/chemo-baseline-anc", "display": "Absolute Neutrophil Count 4200/uL (adequate)"],
                ["reference": "Observation/chemo-baseline-platelets", "display": "Platelet Count 310 K/uL (normal)"],
                ["reference": "Observation/chemo-baseline-creatinine", "display": "Creatinine 1.0 mg/dL (excellent renal function)"],
                ["reference": "Observation/chemo-baseline-bilirubin", "display": "Total Bilirubin 0.8 mg/dL (normal liver function)"],
                ["reference": "Observation/chemo-baseline-ast", "display": "AST 28 U/L (normal)"],
                ["reference": "Observation/chemo-baseline-alt", "display": "ALT 32 U/L (normal)"]
            ],
            "conclusion": "All baseline laboratory parameters within normal limits and appropriate for initiation of FOLFOX chemotherapy. Excellent organ function with no contraindications to treatment."
        ],
        "port-placement": [
            "resourceType": "Procedure", "id": "port-placement", "status": "completed",
            "code": ["coding": [["system": "http://snomed.info/sct", "code": "425362007", "display": "Insertion of central venous access port"]], "text": "Insertion of Implantable Central Venous Port"],
            "subject": ["reference": "Patient/mock"], "performedDateTime": "2023-12-18T10:00:00Z",
            "performer": [["actor": ["display": "Dr. Michael Thompson, MD, Interventional Radiology"]]],
            "reasonCode": [["text": "Vascular access for adjuvant FOLFOX chemotherapy"]],
            "outcome": ["text": "Successful placement of single-lumen PowerPort via right internal jugular vein approach under ultrasound and fluoroscopic guidance. Port pocket created in right chest wall. Good blood return and function confirmed. No immediate complications."],
            "note": [["text": "Port ready for use after 24-48 hours. Patient counseled on port care and precautions."]]
        ],
        "folfox-cycle1": [
            "resourceType": "MedicationRequest", "id": "folfox-cycle1", "status": "active",
            "intent": "order", 
            "medicationCodeableConcept": ["text": "FOLFOX Regimen - Cycle 1 of 12"],
            "subject": ["reference": "Patient/mock"], 
            "authoredOn": "2023-12-20T09:00:00Z",
            "requester": ["display": "Dr. Evelyn Davis, MD, Medical Oncology"],
            "dosageInstruction": [[
                "text": "FOLFOX Protocol - Day 1 and Day 2: Day 1: Oxaliplatin 85 mg/m² IV over 2 hours, Leucovorin 400 mg/m² IV over 2 hours (concurrent with oxaliplatin), 5-FU 400 mg/m² IV bolus, then 5-FU 2400 mg/m² IV continuous infusion over 46 hours via ambulatory pump. Day 2: Disconnect pump, flush port. Repeat cycle every 14 days for total of 12 cycles (6 months). Pre-medications: Ondansetron 8mg IV and Dexamethasone 12mg IV before each cycle."
            ]],
            "note": [["text": "Standard adjuvant FOLFOX protocol based on clinical trial data showing survival benefit in node-positive colon cancer."]]
        ]
    ]
}
