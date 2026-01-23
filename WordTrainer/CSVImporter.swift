import Foundation

/// Simple CSV importer for two-column CSV files (native,foreign).
/// - Rules:
///   - Handles quoted fields with double quotes according to RFC4180-ish rules (double double-quotes for escaped quotes).
///   - Trims whitespace around fields.
///   - Skips empty lines and lines that look like a header containing 'native' or 'foreign'.
struct CSVImporter {
    static func parseCSV(_ data: Data) -> [(String, String)] {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            return []
        }
        var result: [(String, String)] = []
        let lines = text.components(separatedBy: CharacterSet.newlines)
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            // skip common header row
            let lower = line.lowercased()
            if lower.contains("native") && lower.contains("foreign") { continue }

            let fields = parseCSVLine(line)
            if fields.count >= 2 {
                let native = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let foreign = fields[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !native.isEmpty && !foreign.isEmpty {
                    result.append((native, foreign))
                }
            }
        }
        return result
    }

    // Basic CSV line parser that returns fields. Handles quoted fields and escaped quotes.
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var i = line.startIndex
        let end = line.endIndex

        while i < end {
            let c = line[i]
            if c == "\"" {
                // consume opening quote
                i = line.index(after: i)
                // read until closing quote
                while i < end {
                    let cc = line[i]
                    if cc == "\"" {
                        let next = line.index(after: i)
                        if next < end && line[next] == "\"" {
                            // escaped quote ""
                            field.append("\"")
                            i = line.index(after: next)
                        } else {
                            // closing quote
                            i = next
                            break
                        }
                    } else {
                        field.append(cc)
                        i = line.index(after: i)
                    }
                }
                // skip optional whitespace between closing quote and comma
                while i < end && line[i].isWhitespace { i = line.index(after: i) }
                // if next is comma, consume it
                if i < end && line[i] == "," { i = line.index(after: i) }
                fields.append(field)
                field = ""
            } else if c == "," {
                // separator outside quotes
                fields.append(field)
                field = ""
                i = line.index(after: i)
            } else {
                // unquoted char
                field.append(c)
                i = line.index(after: i)
            }
        }

        // append final field
        fields.append(field)
        return fields
    }
}
