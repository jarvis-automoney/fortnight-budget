//
//  MainApp.swift
//  FortnightBudget
//
//  CLI entry point + demo mode.
//  In production, this would be @main for SwiftUI App.
//

import Foundation

// MARK: - CLI Demo (for testing without Xcode)

@main
struct Main {
    static func main() {
        print("╔══════════════════════════════════════════╗")
        print("║     Fortnight Budget — CLI Demo         ║")
        print("╚══════════════════════════════════════════╝")
        print()
        
        // 1. Test pay cycle service
        let service = PayCycleService()
        let parser = NaturalLanguageParser()
        
        // Demo pay calculation
        let now = Date()
        let calendar = Calendar.current
        guard let nextPay = calendar.date(byAdding: .day, value: 5, to: now) else {
            print("Failed to calculate dates")
            return
        }
        
        // Sample bills for AU user
        let bills: [Bill] = [
            Bill(name: "Rent", amount: 1200, dueDayOfMonth: 1, category: .housing),
            Bill(name: "Electricity (Synergy)", amount: 218, dueDayOfMonth: 28, category: .utilities),
            Bill(name: "Internet (AussieBB)", amount: 99, dueDayOfMonth: 25, category: .utilities),
            Bill(name: "Phone (Boost)", amount: 30, dueDayOfMonth: 26, category: .utilities),
            Bill(name: "Netflix", amount: 16.99, dueDayOfMonth: 27, category: .entertainment),
            Bill(name: "Car Insurance (RAC)", amount: 185, dueDayOfMonth: 15, category: .insurance),
            Bill(name: "Health Insurance", amount: 245, dueDayOfMonth: 10, category: .health),
        ]
        
        print("📅 Your Pay Cycle: Fortnightly")
        print("   Next Pay Date: \(formatDate(nextPay))")
        print()
        
        // Available balance
        let available = service.availableUntilNextPay(
            currentBalance: 2500,
            nextPayDate: nextPay,
            payAmount: 3200,
            bills: bills,
            recentTransactions: []
        )
        
        print("💰 Available Until Next Pay")
        print("   Balance:             $\(formatDecimal(available.balance))")
        print("   Bills Due:           $\(formatDecimal(available.totalBillsDue))")
        print("   Next Pay:            \(formatDate(available.nextPayDate))")
        print("   Days Until Pay:      \(available.daysUntilPay) days")
        print("   Alert:               \(available.alert.rawValue)")
        print()
        
        // Projection
        let calendarDays = 14
        let startDate = calendar.date(byAdding: .day, value: -calendarDays/2, to: nextPay) ?? now
        let projection = service.dailyProjection(
            startDate: startDate,
            endDate: nextPay,
            income: 3200,
            bills: bills,
            transactions: []
        )
        
        print("📊 Daily Balance Projection")
        print("   ┌──────────┬────────────┬────────────────────┐")
        print("   │ Date     │ Balance    │ Bills Due          │")
        print("   ├──────────┼────────────┼────────────────────┤")
        
        for day in projection {
            let dateStr = formatDateShort(day.date)
            let balStr = formatDecimal(day.balance).padding(toLength: 10, withPad: " ", startingAt: 0)
            let billsStr = day.billsDue.isEmpty ? "—" : day.billsDue.map { $0.name }.joined(separator: ", ")
            print("   │ \(dateStr) │ $\(balStr) │ \(billsStr.prefix(18))")
        }
        
        print("   └──────────┴────────────┴────────────────────┘")
        print()
        
        // 3. Test natural language parser
        print("✏️  Natural Language Entry")
        let testInputs = [
            "coles 85.50 grocery",
            "salary 3500",
            "netflix 16.99",
            "uber 24.50 transport",
            "coffee 5",
            "synergy 218 electricity",
            "rent 1200",
        ]
        
        for input in testInputs {
            if let parsed = parser.parse(input) {
                let desc = parsed.description.padding(toLength: 25, withPad: " ", startingAt: 0)
                let amt = parsed.amount.map { "$\(formatDecimal($0))" } ?? "?"
                let cat = parsed.category?.rawValue ?? "auto-detect"
                print("   「\(input)」→ \(desc) \(amt) [\(cat)]")
            } else {
                print("   「\(input)」→ failed to parse")
            }
        }
        
        print()
        
        // 4. Summary
        print("🏁 Fortnight Budget Demo Complete")
        print("   Pricing: Free / $8.99/mo Plus / $12.99/mo Pro")
        print("   Unique:  AU fortnightly pay cycle alignment")
        print("   Status:  Landing page live at jarvis-automoney.github.io/fortnight-budget")
    }
}

// MARK: - Helpers

private func formatDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "d MMM yyyy"
    return f.string(from: date)
}

private func formatDateShort(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "d MMM"
    return f.string(from: date)
}

private func formatDecimal(_ d: Decimal) -> String {
    let ns = NSDecimalNumber(decimal: d)
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 2
    f.maximumFractionDigits = 2
    return f.string(from: ns) ?? "0.00"
}

// MARK: - String padding helper

private extension String {
    func padding(toLength length: Int, withPad pad: String, startingAt: Int) -> String {
        if count >= length { return String(prefix(length)) }
        return self + String(repeating: pad, count: length - count)
    }
}
