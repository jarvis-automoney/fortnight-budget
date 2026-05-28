//
//  PayCycleService.swift
//  FortnightBudget
//
//  Core business logic: computes available balance per pay period,
//  aligns bills to pay cycles, and provides the "available until next pay"
//  figure shown in the main UI.
//

import Foundation

final class PayCycleService {
    
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Australia/Perth")!
        return cal
    }()
    
    // MARK: - Pay Periods
    
    /// Generate pay periods surrounding a given date.
    /// Returns past (for reference), current, and future periods.
    func payPeriods(around date: Date, cycle: PayCycle, nextPayDate: Date, count: Int = 5) -> [PayPeriod] {
        guard cycle.daysInCycle > 0 else { return [] }
        
        let daysPerCycle = cycle.daysInCycle
        var periods: [PayPeriod] = []
        
        // Calculate how many cycles back/forward
        let halfCount = count / 2
        
        for offset in (-halfCount...halfCount) {
            let daysOffset = offset * daysPerCycle
            guard let periodStart = calendar.date(byAdding: .day, value: daysOffset, to: nextPayDate),
                  let periodEnd = calendar.date(byAdding: .day, value: daysPerCycle, to: periodStart) else {
                continue
            }
            
            let isCurrent = (periodStart...periodEnd).contains(date)
            let payAmount: Decimal = 1000  // placeholder, will be set from state
            
            let period = PayPeriod(
                startDate: periodStart,
                endDate: periodEnd,
                income: isCurrent ? payAmount : payAmount
            )
            periods.append(period)
        }
        
        return periods
    }
    
    // MARK: - Available Balance Calculation
    
    /// The core algorithm: how much money is available between now and the next payday,
    /// after accounting for all bills due in between.
    func availableUntilNextPay(
        currentBalance: Decimal,
        nextPayDate: Date,
        payAmount: Decimal,
        bills: [Bill],
        recentTransactions: [Transaction]
    ) -> AvailableBalance {
        let now = Date()
        guard nextPayDate > now else {
            return AvailableBalance(balance: currentBalance, nextPayDate: nextPayDate, billsDue: [], alert: .overdue)
        }
        
        // Find bills due between now and next pay
        let billsDue = bills.filter { bill in
            guard bill.isActive else { return false }
            let dueDate = billDueDate(bill: bill, after: now, before: nextPayDate)
            return dueDate != nil
        }
        
        let totalBillsDue = billsDue.reduce(0) { $0 + $1.amount }
        
        // Find recent spending (since last pay date)
        let lastPayDate = calendar.date(byAdding: .day, value: -(14), to: nextPayDate) ?? now
        let spendingSinceLastPay = recentTransactions
            .filter { $0.date >= lastPayDate && $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }
        
        let projectedAvailable = currentBalance - totalBillsDue
        
        // Alert logic
        let alert: AlertLevel
        if projectedAvailable <= 0 {
            alert = .overdrawn
        } else if projectedAvailable < (payAmount * 0.1) {
            alert = .tight
        } else {
            alert = .ok
        }
        
        return AvailableBalance(
            balance: projectedAvailable,
            nextPayDate: nextPayDate,
            billsDue: billsDue,
            totalBillsDue: totalBillsDue,
            spendingSinceLastPay: spendingSinceLastPay,
            payAmount: payAmount,
            alert: alert
        )
    }
    
    // MARK: - Bill Due Date Calculation
    
    /// Find the next due date for a recurring bill within a date range.
    private func billDueDate(bill: Bill, after: Date, before: Date) -> Date? {
        let currentMonth = calendar.component(.month, from: after)
        let currentYear = calendar.component(.year, from: after)
        
        // Try current month first
        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        components.day = min(bill.dueDayOfMonth, 28)  // cap at 28 for safety
        
        if let dueThisMonth = calendar.date(from: components) {
            if dueThisMonth >= after && dueThisMonth <= before {
                return dueThisMonth
            }
        }
        
        // Try next month
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: after) {
            let nextMonthVal = calendar.component(.month, from: nextMonth)
            let nextYear = calendar.component(.year, from: nextMonth)
            components.year = nextYear
            components.month = nextMonthVal
            components.day = min(bill.dueDayOfMonth, 28)
            
            if let dueNextMonth = calendar.date(from: components) {
                if dueNextMonth >= after && dueNextMonth <= before {
                    return dueNextMonth
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Fortnightly Budget Allocation
    
    /// Allocate bills/expenses across the current fortnight.
    /// Income is assigned to the first day of the cycle.
    /// Bills are mapped to their due dates.
    /// Returns a daily balance projection for the cycle.
    func dailyProjection(
        startDate: Date,
        endDate: Date,
        income: Decimal,
        bills: [Bill],
        transactions: [Transaction]
    ) -> [DayBalance] {
        var projection: [DayBalance] = []
        var runningBalance = income  // start with pay
        
        var currentDate = startDate
        while currentDate <= endDate {
            // Check if any bill falls on this day
            let dayBills = bills.filter { bill in
                calendar.component(.day, from: currentDate) == bill.dueDayOfMonth && bill.isActive
            }
            
            // Check if any transaction falls on this day
            let dayTx = transactions.filter { tx in
                calendar.isDate(tx.date, inSameDayAs: currentDate)
            }
            
            let billsAmount = dayBills.reduce(0) { $0 + $1.amount }
            let txAmount = dayTx.reduce(0) { $0 + $1.amount }
            
            runningBalance -= billsAmount
            runningBalance -= txAmount
            
            projection.append(DayBalance(
                date: currentDate,
                balance: runningBalance,
                billsDue: dayBills,
                transactions: dayTx
            ))
            
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        
        return projection
    }
}

// MARK: - Supporting Types

struct AvailableBalance {
    let balance: Decimal
    let nextPayDate: Date
    let billsDue: [Bill]
    let totalBillsDue: Decimal
    let spendingSinceLastPay: Decimal
    let payAmount: Decimal
    let alert: AlertLevel
    
    init(balance: Decimal, nextPayDate: Date, billsDue: [Bill],
         totalBillsDue: Decimal = 0, spendingSinceLastPay: Decimal = 0,
         payAmount: Decimal = 0, alert: AlertLevel = .ok) {
        self.balance = balance
        self.nextPayDate = nextPayDate
        self.billsDue = billsDue
        self.totalBillsDue = totalBillsDue
        self.spendingSinceLastPay = spendingSinceLastPay
        self.payAmount = payAmount
        self.alert = alert
    }
    
    var daysUntilPay: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextPayDate).day ?? 0
    }
}

struct DayBalance: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Decimal
    let billsDue: [Bill]
    let transactions: [Transaction]
}

enum AlertLevel: String {
    case ok = "Looking Good"
    case tight = "A Bit Tight"
    case overdrawn = "Overdrawn"
    case overdue = "Payday Overdue"
}
