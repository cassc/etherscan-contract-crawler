// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error CallerIsNotTheOwner();

abstract contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert CallerIsNotTheOwner();
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}