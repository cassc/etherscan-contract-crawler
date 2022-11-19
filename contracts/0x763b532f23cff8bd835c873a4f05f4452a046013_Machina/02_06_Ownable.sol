// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Short and Simple Ownable by 0xInuarashi
// Ownable follows EIP-173 compliant standard

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "onlyOwner not owner!"); _; }
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}