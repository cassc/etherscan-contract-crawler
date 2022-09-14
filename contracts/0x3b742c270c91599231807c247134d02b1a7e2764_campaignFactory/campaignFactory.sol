/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

pragma solidity >=0.4.0 <0.7.0;

contract campaignFactory{
  // this is a contract that deployes another contract;
  address[] public deployedCampaigns;
  function createCampaign(uint minimum) public {
    address newCampaign = new Campaign(minimum,msg.sender);// passe the sender address 
    // since one contract is deploying another we have to send the sender addr if not it will take the this contarct address as the sender whic is not true; 
    deployedCampaigns.push(newCampaign);
  }
  function getdeployedCampaigns() public view returns (address[]){
    return deployedCampaigns;
  }
}

contract Campaign {
    struct Request{
    string description;
    uint value;
    address recipient;
    bool complete;
    uint approvalCount;
    mapping(address => bool) approvals; // mapping is a refference type
  }
  //creating an array of request
  Request[] public  requests;

  address public manager;
  uint public minimumContribution;
  mapping(address => bool) public approvers;
  uint  public approversCount; // total number of contributers;

  //  lockdown the access
  modifier restricted() {
    require(msg.sender == manager);
    _;
  }

  constructor(uint minimum, address creator ) public {
    manager = creator;
    minimumContribution = minimum;
  }
  function contribute()public payable{
    require(msg.value > minimumContribution);
    approvers[msg.sender] = true;
    approversCount++;
  }
 function createRequest(string description,uint value,address recipient) public restricted{
   Request memory newRequest = Request({
     description:description,
     value:value,
     recipient:recipient,
     complete:false,
     approvalCount:0
   });
   requests.push(newRequest);
   }
   function approveRequest(uint index)public{
     
     Request storage request = requests[index];

     require(approvers[msg.sender]);
     require(!request.approvals[msg.sender]); // if he already votted returns true ,negate that to kick hime out

     //setting value to true
     request.approvals[msg.sender] = true;
     request.approvalCount++;
   }
   function finalizeRequest(uint index)public restricted{
     Request storage request = requests[index]; // we want ot modify actual array;
     // make suer that we have the mejority of approvals ie 50%;
     require(request.approvalCount > (approversCount/2));
     require(!request.complete);
     // now transfer the money to  the recepient
     request.recipient.transfer(request.value);
     request.complete = true;
   }

   function getSummery()public view returns(uint,uint,uint,uint,address){
     return(
       minimumContribution,
       address(this).balance,
       requests.length,
       approversCount,
       manager     );
   }
   function getRequestCount()public view returns(uint){
     return requests.length;
   }


}