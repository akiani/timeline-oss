// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import UIKit

/// Service for fuzzy matching medical terms in text and creating highlighted ranges
class AnnotationMatcher {
    
    /// Match medical term annotations in text and return all found ranges
    func matchAnnotations(
        text: String,
        medicalTerms: [MedicalTermAnnotation]
    ) -> [MatchedAnnotation] {
        
        let nsText = NSString(string: text)
        var matchedAnnotations: [MatchedAnnotation] = []
        
        for term in medicalTerms {
            var ranges: [NSRange] = []
            
            // Try primary term and all alternatives
            let searchTerms = [term.term] + term.alternatives
            
            for searchTerm in searchTerms {
                let foundRanges = findAllMatches(
                    searchTerm: searchTerm,
                    in: nsText
                )
                ranges.append(contentsOf: foundRanges)
            }
            
            // Remove duplicates and overlaps
            ranges = mergeOverlappingRanges(ranges)
            
            if !ranges.isEmpty {
                matchedAnnotations.append(
                    MatchedAnnotation(annotation: term, ranges: ranges)
                )
            }
        }
        
        return matchedAnnotations
    }
    
    /// Find all matches for a search term in text
    private func findAllMatches(searchTerm: String, in text: NSString) -> [NSRange] {
        var ranges: [NSRange] = []
        
        // Case-insensitive search with word boundary considerations
        let options: NSString.CompareOptions = [
            .caseInsensitive,
            .diacriticInsensitive
        ]
        
        var searchStart = 0
        while searchStart < text.length {
            let remainingRange = NSRange(
                location: searchStart,
                length: text.length - searchStart
            )
            
            let foundRange = text.range(
                of: searchTerm,
                options: options,
                range: remainingRange
            )
            
            if foundRange.location == NSNotFound {
                break
            }
            
            // Validate match to avoid partial word matches where inappropriate
            if isValidMatch(range: foundRange, term: searchTerm, in: text) {
                ranges.append(foundRange)
            }
            
            searchStart = foundRange.location + foundRange.length
        }
        
        return ranges
    }
    
    /// Validate that a match is appropriate (avoid partial matches for certain terms)
    private func isValidMatch(range: NSRange, term: String, in text: NSString) -> Bool {
        // For very short terms, be more strict about word boundaries
        if term.count <= 2 {
            return isWordBoundaryMatch(range: range, term: term, in: text)
        }
        
        // For medical codes (containing numbers/special chars), be more flexible
        if containsMedicalCodePattern(term) {
            return true
        }
        
        // For longer terms, check for reasonable word boundaries
        return isReasonableMatch(range: range, term: term, in: text)
    }
    
    /// Check if term contains patterns typical of medical codes
    private func containsMedicalCodePattern(_ term: String) -> Bool {
        let medicalCodePattern = try? NSRegularExpression(pattern: "[A-Za-z]\\d|\\d[A-Za-z]|[TMN]\\d", options: [])
        let range = NSRange(location: 0, length: term.count)
        return medicalCodePattern?.firstMatch(in: term, options: [], range: range) != nil
    }
    
    /// Check strict word boundaries for short terms
    private func isWordBoundaryMatch(range: NSRange, term: String, in text: NSString) -> Bool {
        let beforeIndex = range.location
        let afterIndex = range.location + range.length
        
        // Check character before
        let beforeOk = beforeIndex == 0 ||
                      isWordBoundary(text.character(at: beforeIndex - 1))
        
        // Check character after
        let afterOk = afterIndex >= text.length ||
                     isWordBoundary(text.character(at: afterIndex))
        
        return beforeOk && afterOk
    }
    
    /// Check reasonable word boundaries for longer terms
    private func isReasonableMatch(range: NSRange, term: String, in text: NSString) -> Bool {
        // For longer medical terms, we're less strict about exact word boundaries
        // but still avoid matching within other words when inappropriate
        let beforeIndex = range.location
        let afterIndex = range.location + range.length
        
        // Avoid matching if we're inside a long alphanumeric string
        let beforeOk = beforeIndex == 0 ||
                      !Character(UnicodeScalar(text.character(at: beforeIndex - 1))!).isLetter ||
                      isWordBoundary(text.character(at: beforeIndex - 1))
        
        let afterOk = afterIndex >= text.length ||
                     !Character(UnicodeScalar(text.character(at: afterIndex))!).isLetter ||
                     isWordBoundary(text.character(at: afterIndex))
        
        return beforeOk && afterOk
    }
    
    /// Check if character represents a word boundary
    private func isWordBoundary(_ char: unichar) -> Bool {
        let character = Character(UnicodeScalar(char)!)
        return character.isWhitespace ||
               character.isPunctuation ||
               character.isSymbol ||
               character.isNewline
    }
    
    /// Merge overlapping ranges and remove duplicates
    private func mergeOverlappingRanges(_ ranges: [NSRange]) -> [NSRange] {
        guard !ranges.isEmpty else { return [] }
        
        // Sort ranges by location
        let sortedRanges = ranges.sorted { $0.location < $1.location }
        var mergedRanges: [NSRange] = []
        
        var currentRange = sortedRanges[0]
        
        for range in sortedRanges.dropFirst() {
            if NSLocationInRange(range.location, currentRange) ||
               range.location <= NSMaxRange(currentRange) {
                // Overlapping or adjacent - merge
                let newLocation = min(currentRange.location, range.location)
                let newEnd = max(NSMaxRange(currentRange), NSMaxRange(range))
                currentRange = NSRange(location: newLocation, length: newEnd - newLocation)
            } else {
                // No overlap - add current and start new
                mergedRanges.append(currentRange)
                currentRange = range
            }
        }
        
        mergedRanges.append(currentRange)
        return mergedRanges
    }
    
    /// Create attributed string with annotation highlighting
    func createAttributedText(
        text: String,
        matchedAnnotations: [MatchedAnnotation],
        baseFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    ) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString(string: text)
        
        // Apply base styling
        attributedString.addAttributes([
            .font: baseFont,
            .foregroundColor: UIColor.label
        ], range: NSRange(location: 0, length: attributedString.length))
        
        // Sort matched annotations by category for consistent highlighting
        let sortedMatches = matchedAnnotations.sorted { 
            $0.annotation.category < $1.annotation.category 
        }
        
        // Apply highlighting for each matched annotation
        for matched in sortedMatches {
            let highlightColor = matched.annotation.categoryColor
            
            for range in matched.ranges {
                // Ensure range is valid
                guard range.location >= 0 && 
                      NSMaxRange(range) <= attributedString.length else {
                    continue
                }
                
                attributedString.addAttributes([
                    .backgroundColor: highlightColor.withAlphaComponent(0.25),
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: highlightColor,
                    .foregroundColor: UIColor.label
                ], range: range)
            }
        }
        
        return attributedString
    }
    
    /// Find which annotation was tapped at a given character index
    func findAnnotationAtIndex(_ index: Int, in matchedAnnotations: [MatchedAnnotation]) -> MedicalTermAnnotation? {
        for matched in matchedAnnotations {
            for range in matched.ranges {
                if NSLocationInRange(index, range) {
                    return matched.annotation
                }
            }
        }
        return nil
    }
}
