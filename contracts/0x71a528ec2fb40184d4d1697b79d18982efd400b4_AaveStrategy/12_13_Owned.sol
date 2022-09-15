// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

abstract contract Owned {
    
    event SetOwner(address indexed user, address indexed newOwner);

    address public owner;

    error Unauthorised();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorised();
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        emit SetOwner(address(0), _owner);
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit SetOwner(msg.sender, newOwner);
    }
}