/**
 * @description Utility class for managing trigger bypass logic.
 * Allows selective bypass of trigger handlers for specific operations
 * like data loads, backfills, or system integrations.
 * 
 * Usage:
 * // Bypass a specific handler
 * TriggerBypassUtil.bypass('CaseTriggerHandler');
 * // ... do work ...
 * TriggerBypassUtil.clearBypass('CaseTriggerHandler');
 */
public class TriggerBypassUtil {
    
    // Session-based bypass map using custom setting or custom metadata
    // For now, using a static map. Consider migrating to Custom Metadata for persistence across batches
    private static Set<String> bypassedHandlers = new Set<String>();
    
    /**
     * @description Bypasses a specific trigger handler for the current transaction.
     * 
     * @param handlerKey The handler key to bypass (e.g., 'CaseTriggerHandler')
     */
    public static void bypass(String handlerKey) {
        bypassedHandlers.add(handlerKey);
        System.debug('Bypassing handler: ' + handlerKey);
    }
    
    /**
     * @description Bypasses multiple trigger handlers for the current transaction.
     * 
     * @param handlerKeys Set of handler keys to bypass
     */
    public static void bypassMultiple(Set<String> handlerKeys) {
        bypassedHandlers.addAll(handlerKeys);
        System.debug('Bypassing handlers: ' + handlerKeys);
    }
    
    /**
     * @description Checks if a specific handler is bypassed.
     * 
     * @param handlerKey The handler key to check
     * @return Boolean true if bypassed, false otherwise
     */
    public static Boolean isBypassed(String handlerKey) {
        return bypassedHandlers.contains(handlerKey);
    }
    
    /**
     * @description Clears the bypass for a specific handler.
     * 
     * @param handlerKey The handler key to clear
     */
    public static void clearBypass(String handlerKey) {
        bypassedHandlers.remove(handlerKey);
        System.debug('Cleared bypass for handler: ' + handlerKey);
    }
    
    /**
     * @description Clears all bypasses for the current transaction.
     * Call this when done with data loads to re-enable all triggers.
     */
    public static void clearAllBypasses() {
        bypassedHandlers.clear();
        System.debug('Cleared all handler bypasses');
    }
    
    /**
     * @description Returns the current set of bypassed handlers.
     * Useful for debugging and testing.
     * 
     * @return Set<String> of bypassed handler keys
     */
    public static Set<String> getBypassedHandlers() {
        return new Set<String>(bypassedHandlers);
    }
}