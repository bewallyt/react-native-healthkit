//
//  Serializers.swift
//  kingstinct-react-native-healthkit
//
//  Created by Robert Herber on 2023-05-31.
//

import Foundation
import HealthKit

let _dateFormatter = ISO8601DateFormatter()

func serializeQuantity(unit: HKUnit, quantity: HKQuantity?) -> [String: Any]? {
  guard let q = quantity else {
    return nil
  }

  return [
    "quantity": q.doubleValue(for: unit),
    "unit": unit.unitString,
  ]
}

func serializeQuantitySample(sample: HKQuantitySample, unit: HKUnit) -> NSDictionary {
  let endDate = _dateFormatter.string(from: sample.endDate)
  let startDate = _dateFormatter.string(from: sample.startDate)

  let quantity = sample.quantity.doubleValue(for: unit)

  return [
    "uuid": sample.uuid.uuidString,
    "device": serializeDevice(_device: sample.device) as Any,
    "quantityType": sample.quantityType.identifier,
    "endDate": endDate,
    "startDate": startDate,
    "quantity": quantity,
    "unit": unit.unitString,
    "metadata": serializeMetadata(metadata: sample.metadata),
    "sourceRevision": serializeSourceRevision(_sourceRevision: sample.sourceRevision) as Any,
  ]
}

func getQuantityFromStatistics(statistics: HKStatistics, options: NSArray) -> HKQuantity? {
  for o in options {
    let str = o as! String
    if str == "cumulativeSum" {
      return statistics.sumQuantity()
    } else if str == "discreteAverage" {
      return statistics.averageQuantity()
    } else if str == "discreteMax" {
      return statistics.maximumQuantity()
    } else if str == "discreteMin" {
      return statistics.minimumQuantity()
    }
  }
  return nil
}

func serializeDataPoint(statistics: HKStatistics, options: NSArray, unit: HKUnit) -> [String: Any]? {
    let quantity = getQuantityFromStatistics(statistics: statistics, options: options)
    let startDate = _dateFormatter.string(from: statistics.startDate)
    let endDate = _dateFormatter.string(from: statistics.endDate)
    let value = quantity?.doubleValue(for: unit) ?? 0.0 // Defaults to 0.0 if quantity is nil

    // Create a dictionary for the data point
    let dataPoint: [String: Any] = [
        "startDate": startDate,
        "endDate": endDate,
        "value": value,
        "unit": unit.unitString,
        "quantityType": statistics.quantityType.identifier
    ]
    return dataPoint
}

func serializeStatsCollection(_ statsCollection: HKStatisticsCollection) -> [String: Any] {
  var serializedCollection: [[String: Any]] = []

  statsCollection.enumerateStatistics(
    from: statsCollection.statistics().first!.startDate,
    to: statsCollection.statistics().last!.endDate
  ) { statistics, stop in
    var serializedStatistic: [String: Any] = [:]

    // This is just an example of the kind of data you might include for each statistic.
    serializedStatistic["startDate"] = _dateFormatter.string(from: statistics.startDate)
    serializedStatistic["endDate"] = _dateFormatter.string(from: statistics.endDate)

    if let quantityType = statistics.quantityType as? HKQuantityType {
      serializedStatistic["quantityType"] = quantityType.identifier
    }

    if let averageQuantity = statistics.averageQuantity() {
      serializedStatistic["averageQuantity"] = serializeUnknownQuantity(quantity: averageQuantity)
    }

    if let sumQuantity = statistics.sumQuantity() {
      serializedStatistic["sumQuantity"] = serializeUnknownQuantity(quantity: sumQuantity)
    }

    // Add the serialized statistics to the collection.
    serializedCollection.append(serializedStatistic)
  }

  return ["statistics": serializedCollection]
}

func serializeDeletedSample(sample: HKDeletedObject) -> NSDictionary {
  return [
    "uuid": sample.uuid.uuidString,
    "metadata": serializeMetadata(metadata: sample.metadata),
  ]
}

func serializeCategorySample(sample: HKCategorySample) -> NSDictionary {
  let endDate = _dateFormatter.string(from: sample.endDate)
  let startDate = _dateFormatter.string(from: sample.startDate)

  return [
    "uuid": sample.uuid.uuidString,
    "device": serializeDevice(_device: sample.device) as Any,
    "categoryType": sample.categoryType.identifier,
    "endDate": endDate,
    "startDate": startDate,
    "value": sample.value,
    "metadata": serializeMetadata(metadata: sample.metadata),
    "sourceRevision": serializeSourceRevision(_sourceRevision: sample.sourceRevision) as Any,
  ]
}

func serializeSource(source: HKSource) -> NSDictionary {

  return [
    "bundleIdentifier": source.bundleIdentifier,
    "name": source.name,
  ]
}

func serializeUnknownQuantity(quantity: HKQuantity) -> [String: Any]? {
  if quantity.is(compatibleWith: HKUnit.percent()) {
    return serializeQuantity(unit: HKUnit.percent(), quantity: quantity)
  }

  if quantity.is(compatibleWith: HKUnit.second()) {
    return serializeQuantity(unit: HKUnit.second(), quantity: quantity)
  }

  if quantity.is(compatibleWith: HKUnit.kilocalorie()) {
    return serializeQuantity(unit: HKUnit.kilocalorie(), quantity: quantity)
  }

  if quantity.is(compatibleWith: HKUnit.count()) {
    return serializeQuantity(unit: HKUnit.count(), quantity: quantity)
  }

  if quantity.is(compatibleWith: HKUnit.meter()) {
    return serializeQuantity(unit: HKUnit.meter(), quantity: quantity)
  }

  if #available(iOS 11, *) {
    if quantity.is(compatibleWith: HKUnit.internationalUnit()) {
      return serializeQuantity(unit: HKUnit.internationalUnit(), quantity: quantity)
    }
  }

  if #available(iOS 13, *) {
    if quantity.is(compatibleWith: HKUnit.hertz()) {
      return serializeQuantity(unit: HKUnit.hertz(), quantity: quantity)
    }
    if quantity.is(compatibleWith: HKUnit.decibelHearingLevel()) {
      return serializeQuantity(unit: HKUnit.decibelHearingLevel(), quantity: quantity)
    }
  }

  if quantity.is(compatibleWith: SpeedUnit) {
    return serializeQuantity(unit: SpeedUnit, quantity: quantity)
  }

  if quantity.is(compatibleWith: METUnit) {
    return serializeQuantity(unit: METUnit, quantity: quantity)
  }

  return nil
}

func serializeMetadata(metadata: [String: Any]?) -> NSDictionary {
  let serialized: NSMutableDictionary = [:]
  if let m = metadata {
    for item in m {
      if let bool = item.value as? Bool {
        serialized.setValue(bool, forKey: item.key)
      }
      if let str = item.value as? String {
        serialized.setValue(str, forKey: item.key)
      }

      if let double = item.value as? Double {
        serialized.setValue(double, forKey: item.key)
      }
      if let quantity = item.value as? HKQuantity {
        if let s = serializeUnknownQuantity(quantity: quantity) {
          serialized.setValue(s, forKey: item.key)
        }
      }
    }
  }
  return serialized
}

func serializeDevice(_device: HKDevice?) -> [String: String?]? {
  guard let device = _device else {
    return nil
  }

  return [
    "name": device.name,
    "firmwareVersion": device.firmwareVersion,
    "hardwareVersion": device.hardwareVersion,
    "localIdentifier": device.localIdentifier,
    "manufacturer": device.manufacturer,
    "model": device.model,
    "softwareVersion": device.softwareVersion,
    "udiDeviceIdentifier": device.udiDeviceIdentifier,
  ]
}

func serializeOperatingSystemVersion(_version: OperatingSystemVersion?) -> String? {
  guard let version = _version else {
    return nil
  }

  let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

  return versionString
}

func serializeSourceRevision(_sourceRevision: HKSourceRevision?) -> [String: Any?]? {
  guard let sourceRevision = _sourceRevision else {
    return nil
  }

  var dict =
    [
      "source": [
        "name": sourceRevision.source.name,
        "bundleIdentifier": sourceRevision.source.bundleIdentifier,
      ],
      "version": sourceRevision.version as Any,
    ] as [String: Any]

  if #available(iOS 11, *) {
    dict["operatingSystemVersion"] = serializeOperatingSystemVersion(
      _version: sourceRevision.operatingSystemVersion)
    dict["productType"] = sourceRevision.productType
  }

  return dict
}

func deserializeHKQueryAnchor(anchor: String) -> HKQueryAnchor? {
  return anchor.isEmpty ? nil : base64StringToHKQueryAnchor(base64String: anchor)
}

func serializeAnchor(anchor: HKQueryAnchor?) -> String? {
  guard let anch = anchor else {
    return nil
  }

  let data = NSKeyedArchiver.archivedData(withRootObject: anch)
  let encoded = data.base64EncodedString()

  return encoded
}
