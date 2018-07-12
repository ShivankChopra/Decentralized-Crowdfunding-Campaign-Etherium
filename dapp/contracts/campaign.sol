pragma solidity ^0.4.24;

contract CampaignFactory{
    address[] public deployedCampaigns;
    
    function createCampaign(uint _minimumContribution) public {
        address newCampaignAddress = new Campaign(_minimumContribution, msg.sender);
        deployedCampaigns.push(newCampaignAddress);
    }
    
    function getAllCampaigns() public view returns(address[]){
        return deployedCampaigns;
    }
}

// represents single campaign
contract Campaign{
    struct Request{         // To represent a spending reuest
        string description;
        uint amount;
        address recipient;
        bool completed;
        mapping(address => bool) approvals;
        uint approvalCount;
    }
    
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    Request[] public requests;
    uint public approversCount;
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    constructor(uint _minimumContribution, address _manager) public {
        minimumContribution = _minimumContribution;
        manager = _manager;
    }
    
    function contribute() public payable {
        require(msg.value > minimumContribution);
        approvers[msg.sender] = true; // sender added to list of approvers
        approversCount++;
    }
    
    function createRequest(string _description, uint _amount, address _recipient) public restricted {
        require(_amount <= address(this).balance); // check if value of the request is greater than contract's balance
        Request memory newRequest = Request({
            description  : _description,
            amount       : _amount,
            recipient    : _recipient,
            completed    : false,
            approvalCount: 0
        });
        requests.push(newRequest);
    }
    
    function approveRequest(uint reqIndex) public {
        Request storage request = requests[reqIndex]; // storage pointer to the particular request
        
        require(approvers[msg.sender]); // if sender of this txn is an approvers
        require(!request.approvals[msg.sender]); // if sender of txn has already not voted
        
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    
    function finalizeRequest(uint reqIndex) restricted public {
        Request storage request = requests[reqIndex];
        
        require(request.approvalCount > approversCount/2); // more than half consensus
        require(!request.completed); // request was not completed previously
        
        request.completed = true;
        request.recipient.transfer(request.amount);
    }
    
    function getSummary() public view returns (uint, uint, uint, uint, address) {
        return (
          minimumContribution,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
    }
}