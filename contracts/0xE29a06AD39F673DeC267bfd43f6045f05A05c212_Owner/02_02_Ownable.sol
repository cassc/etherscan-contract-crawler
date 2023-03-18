//SPDX-License-Identifier: None
pragma solidity =0.7.6;

contract Ownable {
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function setOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }
}