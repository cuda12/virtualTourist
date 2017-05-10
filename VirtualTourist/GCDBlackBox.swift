//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 24.02.17 based on the GCDBlackbox by Jarrod Parkers, Udacity
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
