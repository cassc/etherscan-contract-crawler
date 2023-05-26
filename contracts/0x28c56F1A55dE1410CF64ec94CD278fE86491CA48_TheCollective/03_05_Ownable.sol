// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Ownable {

    address public owner;

    constructor() {owner = msg.sender;}

    modifier onlyOwner {
        require(owner == msg.sender, "Not Owner!");
        _;}
    function transferOwnership(address new_) external onlyOwner {owner = new_;}
}

interface IOwnable {
    function owner() external view returns (address);
}