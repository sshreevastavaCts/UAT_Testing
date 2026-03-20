@isTest
public class CollectCountryStateCitydetailsTest {
    @testSetup
    static void setup() {
        // Create Country__c
        Country__c country = new Country__c(Name = 'TestCountry');
        insert country;

        // Create State__c
        State__c state = new State__c(Name = 'TestState', Country__c = country.Id);
        insert state;

        // Create City__c
        City__c city = new City__c(Name = 'TestCity', State__c = state.Id);
        insert city;
    }

    @isTest
    static void testGetLocationData() {
        Test.startTest();
        List<CollectCountryStateCitydetails.CountryWrapper> result = CollectCountryStateCitydetails.getLocationData();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'There should be at least one country');
        Boolean foundCountry = false, foundState = false, foundCity = false;
        for (CollectCountryStateCitydetails.CountryWrapper cw : result) {
            if (cw.name == 'TestCountry') {
                foundCountry = true;
                System.assert(cw.states.size() > 0, 'Country should have states');
                for (CollectCountryStateCitydetails.StateWrapper sw : cw.states) {
                    if (sw.name == 'TestState') {
                        foundState = true;
                        System.assert(sw.cities.size() > 0, 'State should have cities');
                        for (CollectCountryStateCitydetails.CityWrapper ciw : sw.cities) {
                            if (ciw.name == 'TestCity') {
                                foundCity = true;
                            }
                        }
                    }
                }
            }
        }
        System.assert(foundCountry, 'TestCountry should be found');
        System.assert(foundState, 'TestState should be found');
        System.assert(foundCity, 'TestCity should be found');
    }
}