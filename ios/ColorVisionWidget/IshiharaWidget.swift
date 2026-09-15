//  IshiharaWidget.swift
//  WidgetKit entry point: the timeline entry, the configuration AppIntent,
//  the per-minute timeline provider, and the widget + bundle.
//
//  Duplicated verbatim into each app's widget target. Requires iOS/iPadOS
//  17 (AppIntents-configured widgets); the host apps stay at iOS 16, so
//  users on 16 get the app and users on 17+ additionally get the widget.

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline entry

struct IshiharaEntry: TimelineEntry {
    let date: Date
    let seed: UInt32
    let selection: PlateSelection
    let showHands: Bool
}

// MARK: - Configuration intent

enum DeficiencyChoice: String, AppEnum {
    case mixed, protan, deutan, tritan

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Plate type")
    static var caseDisplayRepresentations: [DeficiencyChoice: DisplayRepresentation] = [
        .mixed:  DisplayRepresentation(title: "Mixed (rotates each minute)"),
        .protan: DisplayRepresentation(title: "Protan (red)"),
        .deutan: DisplayRepresentation(title: "Deutan (green)"),
        .tritan: DisplayRepresentation(title: "Tritan (blue-yellow)"),
    ]

    var selection: PlateSelection {
        switch self {
        case .mixed:  return .mixed
        case .protan: return .fixed(.protan)
        case .deutan: return .fixed(.deutan)
        case .tritan: return .fixed(.tritan)
        }
    }
}

struct IshiharaConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Ishihara Clock"
    static var description = IntentDescription("The hour hidden in a regenerating colorblindness plate.")

    @Parameter(title: "Plate type", default: .mixed)
    var deficiency: DeficiencyChoice

    @Parameter(title: "Show clock hands", default: true)
    var showHands: Bool
}

// MARK: - Timeline provider

struct IshiharaProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> IshiharaEntry {
        entry(for: Date(), selection: .mixed, showHands: true, radius: 80)
    }

    func snapshot(for configuration: IshiharaConfigIntent, in context: Context) async -> IshiharaEntry {
        entry(for: Date(),
              selection: configuration.deficiency.selection,
              showHands: configuration.showHands,
              radius: radiusHint(for: context.family))
    }

    func timeline(for configuration: IshiharaConfigIntent, in context: Context) async -> Timeline<IshiharaEntry> {
        let radius = radiusHint(for: context.family)
        let now = Date()
        let cal = Calendar.current
        let startOfMinute = cal.date(from: cal.dateComponents([.year, .month, .day, .hour, .minute], from: now)) ?? now

        var entries: [IshiharaEntry] = []
        for i in 0..<60 {
            let date = startOfMinute.addingTimeInterval(Double(i) * 60)
            entries.append(entry(for: date,
                                 selection: configuration.deficiency.selection,
                                 showHands: configuration.showHands,
                                 radius: radius))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(for date: Date, selection: PlateSelection, showHands: Bool, radius: CGFloat) -> IshiharaEntry {
        IshiharaEntry(date: date,
                      seed: IshiharaPlate.seed(for: date, radius: radius),
                      selection: selection,
                      showHands: showHands)
    }

    /// Approximate plate radius per family, used only so the seed (which
    /// folds in the rounded radius, like the web clock) is stable for the
    /// family. The view recomputes the exact plate from its real size.
    private func radiusHint(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemLarge: return 150
        default:           return 75
        }
    }
}

// MARK: - Widget

struct IshiharaClockWidget: Widget {
    let kind = "IshiharaClockWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: IshiharaConfigIntent.self, provider: IshiharaProvider()) { entry in
            IshiharaWidgetView(entry: entry)
        }
        .configurationDisplayName("Ishihara Clock")
        .description("The hour hidden in a regenerating colorblindness plate.")
        .supportedFamilies([.systemLarge])
    }
}

@main
struct IshiharaWidgetBundle: WidgetBundle {
    var body: some Widget {
        IshiharaClockWidget()
    }
}
