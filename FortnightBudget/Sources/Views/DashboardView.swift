//
//  Views.swift
//  FortnightBudget
//
//  SwiftUI views for the core user experience.
//  Designed for iOS 17+. The onboarding flow (6 screens)
//  and main dashboard.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Onboarding View 1: Pay Cycle Selection

struct PayCycleSelectionView: View {
    @State private var selectedCycle: PayCycle = .fortnightly
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Your money.\nYour pay cycle.")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("How often do you get paid?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                ForEach(PayCycle.allCases) { cycle in
                    Button(action: { selectedCycle = cycle }) {
                        HStack {
                            Text(cycle.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCycle == cycle {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(selectedCycle == cycle ?
                            Color.green.opacity(0.1) : Color.clear)
                    }
                    
                    if cycle != PayCycle.allCases.last {
                        Divider()
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(destination: NextPayDateView(cycle: selectedCycle)) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("Setup")
    }
}

// MARK: - Onboarding View 2: Next Pay Date

struct NextPayDateView: View {
    let cycle: PayCycle
    @State private var payDate = Date()
    @State private var payAmount: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("When's your next payday?")
                .font(.title2)
                .fontWeight(.bold)
            
            DatePicker("Next Pay Date",
                       selection: $payDate,
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)
            
            Text("And how much will it be?")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("$")
                    .font(.title)
                    .foregroundColor(.secondary)
                TextField("3,200", text: $payAmount)
                    .keyboardType(.decimalPad)
                    .font(.title)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(destination: BillSetupView(
                cycle: cycle,
                payDate: payDate,
                payAmount: Decimal(string: payAmount) ?? 0
            )) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(payAmount.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(payAmount.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Onboarding View 3: Quick Bills

struct BillSetupView: View {
    let cycle: PayCycle
    let payDate: Date
    let payAmount: Decimal
    
    @State private var billInput: String = ""
    @State private var addedBills: [Bill] = []
    @State private var availableBalance: Decimal = 0
    
    private let parser = NaturalLanguageParser()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("What bills are due before your next pay?")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Natural language input
            HStack {
                TextField("rent 1200", text: $billInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    addBill()
                }
                .disabled(billInput.isEmpty)
            }
            .padding(.horizontal)
            
            // Added bills list
            List {
                ForEach(addedBills) { bill in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(bill.name)
                                .fontWeight(.medium)
                            Text("Due \(ordinal(bill.dueDayOfMonth))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("$\(formatDecimal(bill.amount))")
                            .fontWeight(.semibold)
                    }
                }
            }
            .listStyle(.plain)
            
            // Total this cycle
            let total = addedBills.reduce(0) { $0 + $1.amount }
            VStack(spacing: 4) {
                Text("Total this cycle: $\(formatDecimal(total))")
                    .fontWeight(.semibold)
                Text("Available: $\(formatDecimal(payAmount - total))")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            NavigationLink(destination: AvailableBalanceView(
                payAmount: payAmount,
                bills: addedBills,
                payDate: payDate
            )) {
                Text("That's all → Show My Balance")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .onAppear {
            availableBalance = payAmount
        }
    }
    
    private func addBill() {
        if let parsed = parser.parse(billInput) {
            let amount = parsed.amount ?? 0
            let name = parsed.description
            let bill = Bill(
                name: name,
                amount: amount,
                dueDayOfMonth: Calendar.current.component(.day, from: Date()),
                category: parsed.category ?? .other
            )
            addedBills.append(bill)
            billInput = ""
        }
    }
    
    private func ordinal(_ n: Int) -> String {
        let suffixes = ["th", "st", "nd", "rd"]
        let mod100 = n % 100
        let suffix: String
        if mod100 >= 11 && mod100 <= 13 {
            suffix = "th"
        } else {
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
    
    private func formatDecimal(_ d: Decimal) -> String {
        let ns = NSDecimalNumber(decimal: d)
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: ns) ?? "0.00"
    }
}

// MARK: - The "Aha" View: Available Balance

struct AvailableBalanceView: View {
    let payAmount: Decimal
    let bills: [Bill]
    let payDate: Date
    let service = PayCycleService()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Hero number
            VStack(spacing: 8) {
                Text("$\(formatDecimal(payAmount - totalBills))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(alertColor)
                
                Text("Available until \(formatDate(payDate))")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("⏳ \(daysUntilPay) days left")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Progress bar
            ProgressView(value: Double(daysIntoCycle), total: 14)
                .tint(.green)
                .padding(.horizontal)
            
            // Breakdown
            VStack(spacing: 12) {
                BreakdownRow(label: "Income", amount: payAmount, color: .green)
                BreakdownRow(label: "Bills", amount: -totalBills, color: .red)
                Divider()
                BreakdownRow(label: "Remaining", amount: payAmount - totalBills, color: .blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Per-day insight
            let perDay = (payAmount - totalBills) / Decimal(max(daysUntilPay, 1))
            Text("💰 $\(formatDecimal(perDay))/day for spending")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Upgrade prompt
            VStack(spacing: 12) {
                NavigationLink(destination: Text("Main Dashboard (Free)")) {
                    Text("Start Budgeting — Free")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button("Try Plus — $0 for 14 days") {
                    // TODO: Payment sheet
                }
                .foregroundColor(.green)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("Your Fortnight")
    }
    
    private var totalBills: Decimal {
        bills.reduce(0) { $0 + $1.amount }
    }
    
    private var daysUntilPay: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: payDate).day ?? 0
    }
    
    private var daysIntoCycle: Int {
        guard let startOfCycle = Calendar.current.date(byAdding: .day, value: -14, to: payDate) else {
            return 7
        }
        return Calendar.current.dateComponents([.day], from: startOfCycle, to: Date()).day ?? 7
    }
    
    private var alertColor: Color {
        let remaining = payAmount - totalBills
        if remaining <= 0 { return .red }
        if remaining < payAmount * 0.1 { return .orange }
        return .green
    }
    
    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM"
        return f.string(from: d)
    }
    
    private func formatDecimal(_ d: Decimal) -> String {
        let ns = NSDecimalNumber(decimal: d)
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: ns) ?? "0.00"
    }
}

// MARK: - Helper Views

struct BreakdownRow: View {
    let label: String
    let amount: Decimal
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("$\(formatDecimal(amount))")
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private func formatDecimal(_ d: Decimal) -> String {
        let ns = NSDecimalNumber(decimal: abs(d))
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: ns) ?? "0.00"
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Dashboard — Fortnight Calendar")
                .tabItem {
                    Label("Budget", systemImage: "calendar.day.timeline.left")
                }
            
            Text("Add Transaction")
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
            
            Text("Bills & Subscriptions")
                .tabItem {
                    Label("Bills", systemImage: "doc.text")
                }
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - App Entry Point

@main
struct FortnightBudgetApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PayCycleSelectionView()
            }
        }
    }
}

#endif
