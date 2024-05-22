({
    init : function(cmp, event, helper) {
        var navService = cmp.find("navService");
        // Sets the route to object record id
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: cmp.get("v.recordId"),
                actionName: 'view'
            }
        };
        var defaultUrl = "#";
        cmp.set("v.pageReference", pageReference);
        navService.generateUrl(pageReference)
            .then($A.getCallback(function(url) {
                cmp.set("v.url", url ? url : defaultUrl);
            }), $A.getCallback(function(error) {
                cmp.set("v.url", defaultUrl);
            }));
    },
    handleClick: function(cmp, event, helper) {
        var navService = cmp.find("navService");
        // Uses the pageReference definition in the init handler
        var pageReference = cmp.get("v.pageReference");
        event.preventDefault();
        navService.navigate(pageReference);
    }
})