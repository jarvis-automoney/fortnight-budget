// 
//  Models.swift
//  FortnightBudget
//
//  Core data models for the Fortnight Budget app.
//  Designed to support Australian fortnightly pay cycles.
//

import Foundation

// MARK: - Pay Cycle

enum PayCycle: String, Codable, CaseIterable, Identifiable {
    case fortnightly = "Fortnightly"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var id: String { rawValue }
    
    var daysInCycle: Int {
        switch self {
        case .weekly: return 7
        case .fortnightly: return 14
        case .monthly: return 30
        }
    }
    
    var cyclesPerYear: Int {
        switch self {
        case .weekly: return 52
        case .fortnightly: return 26
        case .monthly: return 12
        }
    }
}

// MARK: - Account

struct Account: Codable, Identifiable {
    let id: UUID
    var name: String
    var type: AccountType
    var balance: Decimal
    var creditLimit: Decimal?      // For credit cards
    var connectedViaOpenBanking: Bool
    var sortOrder: Int
    
    init(name: String, type: AccountType, balance: Decimal = 0,
         creditLimit: Decimal? = nil, connected: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.balance = balance
        self.creditLimit = creditLimit
        self.connectedViaOpenBanking = connected
        self.sortOrder = sortOrder
    }
}

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case transaction = "Transaction"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case offset = "Offset"
    case loan = "Loan"
    case investment = "Investment"
    case superannuation = "Super"
    
    var id: String { rawValue }
}

// MARK: - Transaction

struct Transaction: Codable, Identifiable {
    let id: UUID
    var amount: Decimal
    var date: Date
    var description: String
    var category: TransactionCategory
    var accountId: UUID
    var isRecurring: Bool
    var recurrenceRule: RecurrenceRule?
    var notes: String
    var importedVia: ImportMethod
    
    init(amount: Decimal, date: Date, description: String,
         category: TransactionCategory, accountId: UUID,
         isRecurring: Bool = false, recurrenceRule: RecurrenceRule? = nil,
         notes: String = "", importedVia: ImportMethod = .manual) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.description = description
        self.category = category
        self.accountId = accountId
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.notes = notes
        self.importedVia = importedVia
    }
}

enum ImportMethod: String, Codable {
    case manual
    case openBanking
    case csvImport
}

enum RecurrenceRule: Codable {
    case daily(interval: Int)
    case weekly(interval: Int, dayOfWeek: Int)
    case fortnightly(interval: Int, dayOfWeek: Int)
    case monthly(interval: Int, dayOfMonth: Int)
    case quarterly(interval: Int, dayOfMonth: Int)
    case annually(interval: Int, month: Int, dayOfMonth: Int)
}

// MARK: - Transaction Categories

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case income = "Income"
    case housing = "Housing (Rent/Mortgage)"
    case utilities = "Utilities"
    case groceries = "Groceries"
    case transport = "Transport"
    case health = "Health"
    case insurance = "Insurance"
    case education = "Education"
    case entertainment = "Entertainment"
    case dining = "Dining Out"
    case shopping = "Shopping"
    case subscriptions = "Subscriptions"
    case debt = "Debt Payments"
    case savings = "Savings/Investments"
    case travel = "Travel"
    case personal = "Personal Care"
    case gifts = "Gifts/Donations"
    case tax = "Tax"
    case other = "Other"
    
    var id: String { rawValue }
    
    var isExpense: Bool { self != .income }
    var isEssential: Bool {
        switch self {
        case .housing, .utilities, .groceries, .health, .insurance:
            return true
        default:
            return false
        }
    }
}

// MARK: - Bill (recurring payment within a pay cycle)

struct Bill: Codable, Identifiable {
    let id: UUID
    var name: String
    var amount: Decimal
    var dueDayOfMonth: Int     // 1-31
    var category: TransactionCategory
    var accountId: UUID?
    var isActive: Bool
    
    init(name: String, amount: Decimal, dueDayOfMonth: Int,
         category: TransactionCategory, accountId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.dueDayOfMonth = dueDayOfMonth
        self.category = category
        self.accountId = accountId
        self.isActive = true
    }
}

// MARK: - Pay Cycle Period

struct PayPeriod: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let isCurrent: Bool
    let income: Decimal
    let totalBills: Decimal
    let remainingBalance: Decimal
    
    var bills: [Bill] = []
    var transactions: [Transaction] = []
    
    init(startDate: Date, endDate: Date, income: Decimal) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.isCurrent = (startDate...endDate).contains(Date())
        self.income = income
        self.totalBills = 0  // computed
        self.remainingBalance = income  // computed after adding bills
    }
}

// MARK: - Subscription Plan

enum BudgetPlan: String, Codable, CaseIterable, Identifiable {
    case free = "Free"
    case plus = "Plus"
    case pro = "Pro"
    
    var id: String { rawValue }
    
    var monthlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .plus: return 8.99
        case .pro: return 12.99
        }
    }
    
    var yearlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .plus: return 85.99
        case .pro: return 124.99
        }
    }
    
    var maxAccounts: Int {
        switch self {
        case .free: return 1
        case .plus: return .max
        case .pro: return .max
        }
    }
    
    var supportsOpenBanking: Bool { self != .free }
    
    var supportsSharedBudget: Bool { self == .pro }
    
    var supportsDebtPlanner: Bool { self == .pro }
    
    var supportsSuperTracking: Bool { self != .free }
}

// MARK: - App State

struct AppState: Codable {
    var userEmail: String?
    var payCycle: PayCycle = .fortnightly
    var nextPayDate: Date
    var payAmount: Decimal = 0
    var plan: BudgetPlan = .free
    var accounts: [Account] = []
    var transactions: [Transaction] = []
    var bills: [Bill] = []
    var onboardingComplete: Bool = false
    
    // Derive current pay period
    func currentPayPeriod() -> PayPeriod? {
        guard payAmount > 0 else { return nil }
        
        let calendar = Calendar.current
        let daysBack = payCycle.daysInCycle / 2
        let periodStart = calendar.date(byAdding: .day, value: -daysBack, to: nextPayDate) ?? nextPayDate
        let periodEnd = nextPayDate
        
        let periodBills = bills.filter { $0.isActive }
        let totalBills = periodBills.reduce(0) { $0 + $1.amount }
        
        return PayPeriod(
            startDate: periodStart,
            endDate: periodEnd,
            income: payAmount
        )
    }
}
