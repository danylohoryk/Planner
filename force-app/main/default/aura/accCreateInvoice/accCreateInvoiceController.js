({
    generateDocument : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var accountId = component.get("v.recordId");
        let startDate = component.get("v.startDate");
        let endDate = component.get("v.endDate");
        let docType = component.get("v.docType");
        let showRate = component.get("v.showRate");
        console.log(showRate);
        urlEvent.setParams({
            "url": "/apex/InvoiceLoader?Id="+accountId+"&startDate="+startDate+"&endDate="+endDate+"&docType="+docType+"&showRate="+showRate,
            "isredirect": "true"
        });
        urlEvent.fire();
    },

    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() 
    }
})