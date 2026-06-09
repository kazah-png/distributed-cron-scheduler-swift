struct CronParser {
    static func matches(cron: String, date: Date = Date()) -> Bool {
        let parts = cron.split(separator: " ")
        guard parts.count == 5 else { return false }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day, .month, .weekday], from: date)
        
        let minute = components.minute!
        let hour = components.hour!
        let day = components.day!
        let month = components.month!
        let weekday = components.weekday! - 1 // ajuste domingo=0
        
        return checkField(parts[0], value: minute) &&
               checkField(parts[1], value: hour) &&
               checkField(parts[2], value: day) &&
               checkField(parts[3], value: month) &&
               checkField(parts[4], value: weekday)
    }
    
    private static func checkField(_ pattern: Substring, value: Int) -> Bool {
        if pattern == "*" { return true }
        if let single = Int(pattern), single == value { return true }
        if pattern.contains(",") {
            let values = pattern.split(separator: ",").compactMap { Int($0) }
            return values.contains(value)
        }
        if pattern.contains("-") {
            let range = pattern.split(separator: "-").compactMap { Int($0) }
            if range.count == 2, value >= range[0] && value <= range[1] { return true }
        }
        if pattern.contains("/") {
            let stepParts = pattern.split(separator: "/")
            if stepParts.count == 2, let step = Int(stepParts[1]), step > 0 {
                let base = stepParts[0] == "*" ? 0 : (Int(stepParts[0]) ?? 0)
                return (value - base) % step == 0
            }
        }
        return false
    }
}