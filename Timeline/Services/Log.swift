// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import os

enum Log {
    static let subsystem = "care.yari.timeline.one"
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let core = Logger(subsystem: subsystem, category: "Core")
}

