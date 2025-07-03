public class CollectCountryStateCitydetails {
    @AuraEnabled(cacheable=true) 
    public static List<CountryWrapper> getLocationData() { 
        Map<Id, List<State__c>> statesMap = new Map<Id, List<State__c>>(); 
        Map<Id, List<City__c>> citiesMap = new Map<Id, List<City__c>>(); 
        
        List<State__c> allStates = [ SELECT Id, Name, Country__c FROM State__c ]; 
        for (State__c s : allStates) { 
            if (!statesMap.containsKey(s.Country__c)) { 
                statesMap.put(s.Country__c, new List<State__c>()); 
            } 
            statesMap.get(s.Country__c).add(s); 
        } 
        List<City__c> allCities = [ SELECT Id, Name, State__c FROM City__c ]; 
        for (City__c c : allCities) { 
            if (!citiesMap.containsKey(c.State__c)) { 
                citiesMap.put(c.State__c, new List<City__c>()); 
            } 
            citiesMap.get(c.State__c).add(c); 
        } 
        List<Country__c> countries = [SELECT Id, Name FROM Country__c]; 
        List<CountryWrapper> result = new List<CountryWrapper>(); 
        for (Country__c country : countries) { 
            CountryWrapper cw = new CountryWrapper(); 
            cw.name = country.Name; 
            cw.states = new List<StateWrapper>(); 
            if (statesMap.containsKey(country.Id)) { 
                for (State__c state : statesMap.get(country.Id)) { 
                    StateWrapper sw = new StateWrapper(); 
                    sw.name = state.Name; 
                    sw.cities = new List<CityWrapper>(); 
                    if (citiesMap.containsKey(state.Id)) { 
                        for (City__c city : citiesMap.get(state.Id)) { 
                            CityWrapper ciw = new CityWrapper(); 
                            ciw.name = city.Name; sw.cities.add(ciw); 
                        } 
                    } 
                    cw.states.add(sw); 
                } 
            } 
            result.add(cw); 
        } 
        return result; 
    } 
    
    public class CityWrapper { 
        @AuraEnabled public String name; 
    } 
    public class StateWrapper { 
        @AuraEnabled public String name; 
        @AuraEnabled public List<CityWrapper> cities; 
    } 
    public class CountryWrapper { 
        @AuraEnabled public String name; 
        @AuraEnabled public List<StateWrapper> states; 
    }
}