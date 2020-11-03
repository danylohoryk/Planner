public with sharing class RedirectToVF {
    public String recordId { get; set; }

    public RedirectToVF(ApexPages.StandardController sController) {
        this.recordId = sController.getId();
    }
    
    public PageReference downloadPDF() {
        //Create Document
        if (System.currentPageReference().getParameters().get('docType') == 'DOCX') {
            PageReference ref = new PageReference('/apex/InvoiceDOCX');
            return this.createDocument(ref);
        }else {
            PageReference ref = new PageReference('/apex/InvoicePDF');
            return this.createDocument(ref);
        }
        
    }

    public PageReference createDocument(PageReference ref){
        ref.getParameters().put('Id', this.recordId);
        ref.getParameters().put('startDate', System.currentPageReference().getParameters().get('startDate'));
        ref.getParameters().put('endDate', System.currentPageReference().getParameters().get('endDate'));
        ref.getParameters().put('docType', System.currentPageReference().getParameters().get('docType'));
        ref.getParameters().put('showRate', System.currentPageReference().getParameters().get('showRate'));
        ContentVersion cv = new ContentVersion();
        cv.Title = 'invoice';
        cv.PathOnClient = 'invoiсe.docx';
        cv.VersionData = ref.getContentAsPdf();
        cv.Origin = 'H';
        insert cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
    
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = this.recordId;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        insert cdl;
        return ref;
    }
}