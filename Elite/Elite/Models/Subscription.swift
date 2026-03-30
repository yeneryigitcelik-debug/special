import Foundation

struct SubscriptionPlan: Identifiable {
    let id: String
    let tier: User.SubscriptionTier
    let name: String
    let price: String
    let period: String
    let features: [String]
    var badge: String?
    var highlight: String?

    static let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "free",
            tier: .free,
            name: "FREE",
            price: "$0",
            period: "",
            features: [
                "10 profiles per day",
                "Basic matching",
                "Text messaging"
            ]
        ),
        SubscriptionPlan(
            id: "com.elite.dating.plus.monthly",
            tier: .plus,
            name: "ÉLITE+",
            price: "$49.99",
            period: "/month",
            features: [
                "Unlimited profiles",
                "See who liked you",
                "5 Super Likes per day",
                "Priority in discovery",
                "Read receipts",
                "Advanced filters"
            ],
            badge: "Popular"
        ),
        SubscriptionPlan(
            id: "com.elite.dating.plus.yearly",
            tier: .plus,
            name: "ÉLITE+ Annual",
            price: "$399.99",
            period: "/year",
            features: [
                "Everything in ÉLITE+ Monthly",
                "Save 33% vs monthly",
                "Profile boost monthly"
            ],
            highlight: "Best Value"
        ),
        SubscriptionPlan(
            id: "com.elite.dating.black.monthly",
            tier: .black,
            name: "ÉLITE BLACK",
            price: "$99.99",
            period: "/month",
            features: [
                "Everything in ÉLITE+",
                "Incognito mode",
                "Unlimited Super Likes",
                "Exclusive events access",
                "Priority support",
                "Weekly profile boost",
                "Travel mode"
            ],
            badge: "Exclusive"
        ),
        SubscriptionPlan(
            id: "com.elite.dating.black.yearly",
            tier: .black,
            name: "ÉLITE BLACK Annual",
            price: "$799.99",
            period: "/year",
            features: [
                "Everything in BLACK Monthly",
                "Save 33% vs monthly",
                "VIP concierge matching"
            ]
        ),
        SubscriptionPlan(
            id: "com.elite.dating.black.lifetime",
            tier: .black,
            name: "ÉLITE BLACK Lifetime",
            price: "$1,999.99",
            period: "one-time",
            features: [
                "Everything in BLACK forever",
                "Founding member badge",
                "Early access to new features",
                "Personal matchmaking sessions",
                "Never pay again"
            ],
            badge: "Founders Only",
            highlight: "Limited"
        )
    ]
}
