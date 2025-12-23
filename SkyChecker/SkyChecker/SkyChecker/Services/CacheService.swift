import Foundation

class CacheService {
    private let cacheDir: URL
    private let maxAge: TimeInterval = 86400
    static let shared = CacheService()
    
    init() {
        cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("SkyChecker")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
    
    func saveSession(_ session: ObservationSession) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(session) {
            try? data.write(to: cacheDir.appendingPathComponent("\(session.cacheKey).json"))
        }
    }
    
    func loadSession(for date: Date, location: ObserverLocation) -> ObservationSession? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let key = "session_\(df.string(from: date))_\(String(format: "%.2f_%.2f", location.latitude, location.longitude))"
        let url = cacheDir.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let session = try? decoder.decode(ObservationSession.self, from: data),
              Date().timeIntervalSince(session.lastUpdated) <= maxAge else { return nil }
        return session
    }
    
    func clearExpiredCache() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        for file in files {
            if let vals = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
               let mod = vals.contentModificationDate, Date().timeIntervalSince(mod) > maxAge {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    func clearAllCache() {
        try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil).forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
    
    func formattedCacheSize() -> String {
        let size = (try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]))?.reduce(0) {
            $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        } ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

