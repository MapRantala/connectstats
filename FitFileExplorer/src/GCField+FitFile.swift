//
//  GCField+FitFile.swift
//  GarminConnect
//
//  Created by Brice Rosenzweig on 08/11/2016.
//  Copyright © 2016 Brice Rosenzweig. All rights reserved.
//

import Foundation

public extension GCField {
    
    static let fitToFieldMap = ["cadence":"WeightedMeanCadence",
                                "distance":"SumDistance",
                                "speed":"WeightedMeanSpeed",
                                "temperature":"WeightedMeanAirTemperature",
                                "heart_rate": "WeightedMeanHeartRate",
                      ]

    public static func field(fitKey:String, activityType:String) -> GCField? {
        var fieldKey = fitToFieldMap[fitKey]
        if fieldKey == nil{
            print("Missing \(fitKey)")
            return nil
        }
        // special case for running
        if fitKey == "speed" && activityType == "running" {
            fieldKey = "WeightedMeanPace"
        }
        return GCField(forKey: fieldKey, andActivityType: activityType)
    }
}
