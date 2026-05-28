//
//  Log.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 12/05/2023.
//

import Foundation
import os

let Log = Logger(subsystem: Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "parkeerassistent",
                 category: "application")
