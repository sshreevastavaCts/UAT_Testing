/**
 * @description Abstract base class for all trigger handlers in the framework.
 * Handlers extend this class and override methods for the events they need to handle.
 * This ensures consistent trigger handling across all objects.
 * 
 * Each handler should:
 * 1. Implement getHandlerKey() to return a unique identifier
 * 2. Override specific event methods (beforeInsert, afterUpdate, etc.)
 * 3. Keep logic delegated and maintainable
 * 4. Respect the bypass utility for selective logic bypass
 */
public abstract class TriggerHandler {
    
    protected TriggerFramework.TriggerContext context;
    
    /**
     * @description Must be implemented by subclasses to return a unique key
     * identifying this handler. Used for registry and bypass logic.
     * Convention: Use "{ObjectName}TriggerHandler" format
     * 
     * @return String unique handler identifier
     */
    public abstract String getHandlerKey();
    
    /**
     * @description Called when records are being inserted (before).
     * Override in subclass if needed.
     * 
     * @param context TriggerContext with trigger metadata
     */
    public virtual void beforeInsert(TriggerFramework.TriggerContext context) {
        // Default: do nothing. Override in subclass.
    }
    
    /**
     * @description Called after records are inserted.
     * Override in subclass if needed.
     * 
     * @param context TriggerContext with trigger metadata
     */
    public virtual void afterInsert(TriggerFramework.TriggerContext context) {
        // Default: do nothing. Override in subclass.
    }
    
    /**
     * @description Called when records are being updated (before).
     * Override in subclass if needed.
     * 
     * @param context TriggerContext with trigger metadata
     */
    public virtual void beforeUpdate(TriggerFramework.TriggerContext context) {
        // Default: do nothing. Override in subclass.
    }
    
    /**
     * @description Called after records are updated.
     * Override in subclass if needed.
     * 
     * @param context TriggerContext with trigger metadata
     */
    public virtual void afterUpdate(TriggerFramework.TriggerContext context) {
        // Default: do nothing. Override in subclass.
    }
    
    /**
     * @description Called when records are being deleted (before).
     * Override in subclass if needed.
     * 
     * @param context TriggerContext with trigger metadata
     */
    public virtual void beforeDelete(TriggerFramework.TriggerContext context) {
        // Default: do nothing. Override in subclass.
    }
    
    /**
     * @description Called after records are deleted.
     * Override in subclass if needed.
     * 
     * @param context TriggerContext with trigger metadata
     */
    public virtual void afterDelete(TriggerFramework.TriggerContext context) {
        // Default: do nothing. Override in subclass.
    }
    
    /**
     * @description Called when records are undeleted.
     * Override in subclass if needed.
     * 
     * @param context TriggerContext with trigger metadata
     */
    public virtual void afterUndelete(TriggerFramework.TriggerContext context) {
        // Default: do nothing. Override in subclass.
    }
}