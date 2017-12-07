//
//  GCDBlackBox.swift
//  ForcedPerspectives App
// this is used to perform any task on a main ui thread
//  Created by StemDot on 12/5/17.
//  Copyright © 2017 Stemdot Business Solution. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
