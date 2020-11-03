public with sharing class Invoice {

    public List<ProjectWrapper> projects { get; set; }
    public Account bankAcc { get; set; }
    public String invoiceDate { get; set; }
    public String invoiceCycle { get; set; }
    public String invoiceNumber { get; set; }
    public String showRate { get; set; }
    public Double total { get; set; }
    public Double totalHours { get; set; }
    public Organization organization { get; set; }
    public String recordId { get; set; }

    public Invoice(ApexPages.StandardController sController){
        Date startDate = Date.valueOf(System.currentPageReference().getParameters().get('startDate'));
        Date endDate = Date.valueOf(System.currentPageReference().getParameters().get('endDate'));
        String rId = System.currentPageReference().getParameters().get('Id');
        System.debug('rId'+ rId);

        String showRate = System.currentPageReference().getParameters().get('showRate');
        String invoiceCycle = System.currentPageReference().getParameters().get('startDate') + ' - ' + System.currentPageReference().getParameters().get('endDate');
        Id bankRecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Bank').getRecordTypeId();
        Date today = Date.today();
        DateTime dt = DateTime.newInstance(today.year(), today.month(),today.day());
        String invoiceNumber = dt.format('yyyyMMdd');
        Double totalAmount = 0;
        Double totalHoursAmount = 0;
        Account acc = [SELECT Id, Currency__c FROM Account WHERE Id =: rId];
        Account bank = [SELECT Id, IBAN__c, Bank_Name__c, Bank_Address__c, Bank_SWIFT_Code__c, Correspondent_Bank_Name__c, Correspondent_Bank_Address__c, Correspondent_Bank_Account__c, 
                        Correspondent_Bank_SWIFT__c, Currency__c, RecordType.Id FROM Account WHERE Currency__c =: acc.Currency__c AND RecordTypeId =: bankRecordTypeId LIMIT 1];
        List<Project_Assignment__c> prjass = [SELECT Id, Project_Assign__r.Name, Employee__r.Name, Cost_Rate_Amount__c, Project_Assign__r.Payment_Type__c, Project_Assign__r.Payable_Dayoffs__c, Service_Name__c, Billable__c FROM Project_Assignment__c WHERE Project_Assign__r.Account__c =: rId];
        List<Timecard__c> timecards = [SELECT Id, Name, Week_Ending__c, Sunday__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Week_Summary__c,
                                         Assignment__c, Assignment__r.Service_Name__c, Assignment__r.Employee__c, Assignment__r.Employee__r.Name, Assignment__r.Cost_Rate_Amount__c, 
                                         Assignment__r.Contract_Number__c FROM Timecard__c WHERE Week_Ending__c >= :startDate AND Week_Ending__c <= :endDate.addDays(6) 
                                                                                                                              AND Assignment__c IN :prjass];
        List<ProjectWrapper> dataForTable = new List<ProjectWrapper>();
        Integer workingHours = this.calculateWorkingDays(startDate, endDate) * 8;

        for (Project_Assignment__c project : prjass) {
            if(project.Billable__c == True){
                System.debug(project.Cost_Rate_Amount__c);
                ProjectWrapper wrapper = new ProjectWrapper();
                wrapper.hoursAmount = 0;
                for (Timecard__c timecard : timecards) {
                    
                    
                    if (project.Id == timecard.Assignment__c && project.Employee__c == timecard.Assignment__r.Employee__c) {
                        Double weekSummary = timecard.Week_Summary__c;
                        List<String> dates = new List<String>{'Sunday__c', 'Monday__c', 'Tuesday__c', 'Wednesday__c', 'Thursday__c', 'Friday__c', 'Saturday__c'};
                        if (startDate.daysBetween(timecard.Week_Ending__c) < 6) {
                            Integer i = 5 - startDate.daysBetween(timecard.Week_Ending__c);
                            while (i >= 0) {
                                weekSummary -= (Double)timecard.get(dates[i]);
                                timecard.put(dates[i], 0);
                                i--;
                            }
                        }
                        if (endDate.daysBetween(timecard.Week_Ending__c) < 7
                            && endDate.daysBetween(timecard.Week_Ending__c) > 0) {
        
                            Integer i = endDate.daysBetween(timecard.Week_Ending__c);
                            while (i > 0) {
                                weekSummary -= (Double)timecard.get(dates[7 - i]);
                                timecard.put(dates[7 - i], 0);
                                i--;
                            }
                        }
                        wrapper.rate = project.Project_Assign__r.Payment_Type__c;
                        wrapper.hoursAmount += weekSummary;
                    }
                }
                wrapper.name = project.Service_Name__c + ' ' + project.Employee__r.Name;
                wrapper.project = project.Project_Assign__r.Name;

                if(project.Project_Assign__r.Payment_Type__c == 'per hour'){
                    wrapper.costRate = project.Cost_Rate_Amount__c;
                    wrapper.amount = wrapper.costRate * wrapper.hoursAmount;
                }else{
                    if(project.Project_Assign__r.Payable_Dayoffs__c == 'Yes'){
                        wrapper.costRate = project.Cost_Rate_Amount__c;
                        wrapper.amount = wrapper.costRate;
                    }else{
                        wrapper.costRate = project.Cost_Rate_Amount__c;
                        wrapper.amount = wrapper.hoursAmount * wrapper.costRate/workingHours;   
                    }            
                }      
                dataForTable.add(wrapper);
                totalHoursAmount+=wrapper.hoursAmount;
                totalAmount += wrapper.amount;
        }
    }
        Organization org = [SELECT Name, Street, City, Country, PostalCode FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
        this.bankAcc = bank;
        this.organization = org;
        this.invoiceDate = String.valueOf(Date.today());
        this.invoiceCycle = invoiceCycle;
        this.invoiceNumber = invoiceNumber;
        this.showRate = showRate;
        this.recordId = sController.getId();
        this.projects = dataForTable;
        this.total = Decimal.valueOf(totalAmount).setScale(2);
        this.totalHours = totalHoursAmount;
    }

    public Integer calculateWorkingDays(Date startDate, Date endDate)  
    {          
         
        Set<Date> holidaysSet = new Set<Date>();  
         
        for(Holiday currHoliday : [SELECT ActivityDate FROM Holiday WHERE ActivityDate = THIS_YEAR])  
        {  
            holidaysSet.add(currHoliday.ActivityDate);  
        }  
         
        Integer workingDays = 0;  
         
        for(integer i=0; i <= startDate.daysBetween(endDate); i++)  
        {  
            Date dt = startDate + i;  
            DateTime currDate = DateTime.newInstance(dt.year(), dt.month(), dt.day());  
            String todayDay = currDate.format('EEEE');  
            if(todayDay != 'Saturday' && todayDay !='Sunday' && (!holidaysSet.contains(dt)))  
                {  
                    workingDays = workingDays + 1;  
                }     
               
        }  
             
        return workingDays;  
    }  

    private class ProjectWrapper {
        public String name {get;set;}
        public String project {get;set;}
        public String rate {get;set;}
        public Double costRate {get;set;}
        public Double hoursAmount {get;set;}
        public Double amount {get;set;}
    }
}