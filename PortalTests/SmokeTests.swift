import Testing

@Suite("Smoke")
struct SmokeTests {
    @Test("Toolchain wired")
    func toolchainWired() {
        #expect(1 + 1 == 2)
    }
}
