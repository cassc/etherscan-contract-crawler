// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Ownable 
{    
    address payable public owner;
    
    constructor() {
        owner = payable(msg.sender);
    }

    event OwnershipTransferred(address indexed from, address indexed to);
    
    modifier onlyOwner() 
    {
        require(msg.sender == owner, "Function accessible only by the owner.");
        _;
    }
}