({
	 doInit : function(component, event, helper) {
        var action = component.get("c.getTaskSubjects");
        action.setParams({
            recordTypeId: component.get("v.recordTypeId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.subjectOptions", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})