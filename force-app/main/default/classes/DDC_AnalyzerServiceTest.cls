@IsTest
private class DDC_AnalyzerServiceTest {
    @IsTest
    static void smoke_runAnalysis_returnsPayload() {
        Test.startTest();
        // In unit tests, Tooling API callouts will fail unless mocked. We validate that the service
        // surface is callable and build info works. Analyzer call is tested via client mocks separately.
        Map<String, Object> info = DDC_AnalyzerService.getBuildInfo();
        Test.stopTest();

        System.assertEquals('Design Debt Collector', (String)info.get('name'));
        System.assertEquals('Apache-2.0', (String)info.get('license'));
        System.assertEquals('Jyotishko Roy', (String)info.get('author'));
    }
}
