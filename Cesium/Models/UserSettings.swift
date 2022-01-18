//
//  UserSettings.swift v.0.3.0
//  shAre
//
//  Created by Rudolf Farkas on 15.03.20.
//  Copyright © 2020 Eric PAJOT. All rights reserved.
//

import Foundation
import RudifaUtilPkg
import UIKit

/// define backing storage in UserDefaults.standard (local to the app)
enum LocalUserDefaults {
    // define keys to defaults
    enum Key: String {
        case opacityBackgroundLevel
    }

    @CodableUserDefault(key: Key.opacityBackgroundLevel, defaultValue: 0.9)
    static var opacityBackgroundLevel: Float
}
