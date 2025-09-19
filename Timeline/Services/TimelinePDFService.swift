// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import UIKit

// MARK: - TimelinePDFService

class TimelinePDFService {
    static let shared = TimelinePDFService()
    private init() {}
    
    // PDF layout constants
    private let pageWidth: CGFloat = 595.2 // A4 width in points
    private let pageHeight: CGFloat = 841.8 // A4 height in points
    private let margin: CGFloat = 32
    
    private var contentWidth: CGFloat { pageWidth - 2 * margin }
    private var contentHeight: CGFloat { pageHeight - 2 * margin }
    
    // Fonts
    private let disclaimerFont = UIFont.systemFont(ofSize: 11)
    private let appTitleFont = UIFont.boldSystemFont(ofSize: 28)
    private let titleFont = UIFont.boldSystemFont(ofSize: 22)
    private let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
    private let bodyFont = UIFont.systemFont(ofSize: 14)
    private let eventTitleFont = UIFont.boldSystemFont(ofSize: 16)
    private let eventDateFont = UIFont.systemFont(ofSize: 12)
    private let eventDescFont = UIFont.systemFont(ofSize: 14)
    private let resourceFont = UIFont.systemFont(ofSize: 13)
    
    // Colors
    private let primaryColor = UIColor(red: 0.35, green: 0.62, blue: 0.53, alpha: 1.0) // Teal
    private let secondaryColor = UIColor(red: 0.94, green: 0.53, blue: 0.30, alpha: 1.0) // Orange
    private let backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0) // Cream
    private let lightGrayColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // Light gray
    private let dateColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0) // Medium gray
    
    /// Generate a user-friendly, multi-page PDF for the timeline
    /// - Parameter timelineData: The TimelineData to export
    /// - Returns: PDF data
    func generatePDF(for timelineData: TimelineData) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        return renderer.pdfData { context in
            // Start first page with background color
            context.beginPage()
            drawPageBackground(context: context)
            
            var currentY: CGFloat = margin
            
            // Enhanced header section
            currentY = drawEnhancedHeader(y: currentY, context: context)
            currentY += 30
            
            // Disclaimer (more compact)
            currentY = drawCompactDisclaimer(y: currentY, context: context)
            currentY += 25
            
            // Get events in reverse chronological order (newest first)
            let sortedEvents = timelineData.keyEvents.sorted {
                let date1 = dateFromString($0.date) ?? Date.distantPast
                let date2 = dateFromString($1.date) ?? Date.distantPast
                return date1 > date2
            }
            
            // Draw events with enhanced styling
            for (index, event) in sortedEvents.enumerated() {
                currentY = drawEnhancedEvent(event, startY: currentY, index: index, context: context)
            }
        }
    }
    
    // MARK: - Drawing Methods
    
    private func drawPageBackground(context: UIGraphicsPDFRendererContext) {
        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)).fill()
    }
    
    private func drawEnhancedHeader(y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y
        
        currentY += 20
        
        // Clean, minimal app title
        let appTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        currentY = drawCenteredText("Yari Timeline", attributes: appTitleAttributes, y: currentY, context: context)
        currentY += 6
        
        // Subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.darkGray
        ]
        currentY = drawCenteredText("Health Timeline Export", attributes: subtitleAttributes, y: currentY, context: context)
        currentY += 8
        
        // Date generated - smaller and subtle
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateText = "Generated on \(dateFormatter.string(from: Date()))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        currentY = drawCenteredText(dateText, attributes: dateAttributes, y: currentY, context: context)
        
        currentY += 15
        
        return currentY
    }
    
    private func drawCompactDisclaimer(y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let disclaimerText = "⚠️ AI-generated content for informational purposes only. Not medical advice. Consult healthcare providers for medical decisions."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]
        
        // Calculate actual text height with proper line spacing
        let textWidth = contentWidth - 24 // Account for padding inside box
        let disclaimerSize = disclaimerText.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: disclaimerAttributes,
            context: nil
        ).size
        
        let padding: CGFloat = 20
        let totalHeight = ceil(disclaimerSize.height) + padding
        
        let newY = checkPageBreak(neededHeight: totalHeight, currentY: y, context: context)
        
        // Draw background box for disclaimer
        let boxRect = CGRect(x: margin, y: newY, width: contentWidth, height: totalHeight)
        UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 8).fill()
        
        // Draw border
        UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0).setStroke()
        let borderPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        borderPath.lineWidth = 0.5
        borderPath.stroke()
        
        // Draw disclaimer text with proper height
        let textRect = CGRect(x: margin + 12, y: newY + 10, width: textWidth, height: ceil(disclaimerSize.height))
        
        let attributedText = NSAttributedString(string: disclaimerText, attributes: disclaimerAttributes)
        attributedText.draw(in: textRect)
        
        return newY + totalHeight
    }
    

    
    private func drawCenteredText(_ text: String, attributes: [NSAttributedString.Key: Any], y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        // Calculate proper text size
        let textSize = text.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size
        
        let textHeight = ceil(textSize.height)
        let newY = checkPageBreak(neededHeight: textHeight, currentY: y, context: context)
        
        let x = (pageWidth - textSize.width) / 2
        text.draw(at: CGPoint(x: x, y: newY), withAttributes: attributes)
        
        return newY + textHeight
    }
    

    
    private func drawEnhancedEvent(_ event: TimelineData.KeyEvent, startY: CGFloat, index: Int, context: UIGraphicsPDFRendererContext) -> CGFloat {
        // Pre-calculate all component heights to ensure proper page breaks
        let formattedDate = formatDateForDisplay(event.date)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: dateColor
        ]
        let dateSize = formattedDate.size(withAttributes: dateAttributes)
        
        // Calculate title height
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 17),
            .foregroundColor: UIColor.black
        ]
        let titleWidth = contentWidth - dateSize.width - 20
        let titleSize = event.title.boundingRect(
            with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: titleAttributes,
            context: nil
        ).size
        
        // Calculate description height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]
        
        let descWidth = contentWidth - 40
        let descSize = event.description.boundingRect(
            with: CGSize(width: descWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: descAttributes,
            context: nil
        ).size
        
        // Calculate total event height
        let titleHeight = ceil(titleSize.height)
        let descHeight = ceil(descSize.height)
        let spacing: CGFloat = 8 // Space between title and description
        let dividerSpacing: CGFloat = 22 // Space for divider and padding
        let totalEventHeight = titleHeight + spacing + descHeight + dividerSpacing
        
        // Check page break with actual calculated height
        let currentY = checkPageBreak(neededHeight: totalEventHeight, currentY: startY, context: context)
        var drawY = currentY
        
        // Draw date - small and elegant on the right
        let dateX = pageWidth - margin - dateSize.width
        formattedDate.draw(at: CGPoint(x: dateX, y: drawY), withAttributes: dateAttributes)
        
        // Draw title with proper height
        let titleRect = CGRect(x: margin, y: drawY, width: titleWidth, height: titleHeight)
        event.title.draw(in: titleRect, withAttributes: titleAttributes)
        drawY += titleHeight + spacing
        
        // Draw description with calculated height
        let descAttributedText = NSAttributedString(string: event.description, attributes: descAttributes)
        let descRect = CGRect(x: margin, y: drawY, width: descWidth, height: descHeight)
        descAttributedText.draw(in: descRect)
        drawY += descHeight
        
        // Subtle divider line
        UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0).setStroke()
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: margin, y: drawY + 8))
        dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: drawY + 8))
        dividerPath.lineWidth = 0.3
        dividerPath.stroke()
        
        return drawY + dividerSpacing
    }
    

    
    @discardableResult
    private func checkPageBreak(neededHeight: CGFloat, currentY: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        if currentY + neededHeight > pageHeight - margin {
            context.beginPage()
            drawPageBackground(context: context)
            return margin
        }
        return currentY
    }
    

    
    private func formatDateForDisplay(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // Helper to get colorful emoji representation for resource types
    private func emojiForResourceType(_ resourceType: String) -> String {
        switch resourceType.lowercased() {
        case "observation":
            return "📈" // Chart with upward trend for observations
        case "documentreference":
            return "📋" // Clipboard for documents
        case "medicationrequest", "medicationstatement":
            return "💊" // Pills icon
        case "immunization":
            return "💉" // Syringe icon
        case "procedure":
            return "🏥" // Hospital icon for procedures
        case "encounter":
            return "👩‍⚕️" // Healthcare worker icon
        case "diagnosticreport":
            return "🔬" // Microscope for lab reports
        case "condition":
            return "🩺" // Stethoscope for conditions
        case "allergyintolerance":
            return "🚨" // Alarm for allergies
        case "careplan":
            return "📝" // Note-taking for care plans
        case "appointment":
            return "📅" // Calendar for appointments
        case "careteam":
            return "👥" // Group of people
        case "goal":
            return "🎯" // Target for goals
        case "communication":
            return "💬" // Speech bubble
        default:
            return "📄" // Default document icon
        }
    }
    
    // Helper function to convert date string to Date
    private func dateFromString(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString)
    }
} 
