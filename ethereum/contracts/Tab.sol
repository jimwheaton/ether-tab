pragma solidity ^0.4.17;


contract TabFactory {
    address[] public deployedTabs;
    
    function createTab() public {
        address newTab = new Tab(msg.sender);
        deployedTabs.push(newTab);
    }
    
    function getDeployedTabs() public view returns (address[]) {
        return deployedTabs;
    }
}


contract Tab {
    
    struct Expense {
        string description;
        uint value;
        address payer;
    }
    
    Expense[] public expenses;
    uint public total;
    uint public totalParticipants;
    uint public totalSettled;
    address public creator;
    address[] public participants;
    mapping(address => bool) public participantsLookup;
    mapping(address => uint) public totalByParticipant;
    mapping(address => bool) public settled;

    function Tab(address sender) public {
        creator = sender;
    }

    function participate() public {
        participantsLookup[msg.sender] = true;
        participants.push(msg.sender);
        totalParticipants += 1;
    }
    
    function addExpense(string description, uint value) public {
        Expense memory expense = Expense({
            description: description,
            value: value,
            payer: msg.sender
        });
        
        expenses.push(expense);
        totalByParticipant[msg.sender] += value;
        total += value;
        
        if(!participantsLookup[msg.sender]) {
            participate();
        }
    }
    
    function leave() public {
        settle();
        delete participantsLookup[msg.sender];
    }

    function getSettlement(address participant) public view returns (int) {
        uint owed = total / totalParticipants;
        uint totalP = totalByParticipant[participant];
        return int(owed - totalP);
    }
    
     function settle() public payable {
        int settlement = getSettlement(msg.sender);
        require(settlement <= 0 || msg.value == uint(settlement));
        settled[msg.sender] = true;
        totalSettled += 1;
    }
    
    function finalize() public {
        require(totalSettled == totalParticipants);
        
        for(uint i = 0; i < totalParticipants; i++) {
            address participant = participants[i];
            int settlement = getSettlement(participant);
            if(settlement < 0) {    // negative number means participant should be payed
                participant.transfer(uint(settlement * -1));
            }
        }
    }
}