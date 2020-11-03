public with sharing class getUsers {
    public getUsers() {

    }
    @AuraEnabled
    public static List<User> getAllUsers(){
        List<User> users = new List<User>([SELECT Id, Name, Profile.Name, (SELECT Project_Assign__r.Name FROM Assignments__r) FROM User]);
        return users;
    }
}