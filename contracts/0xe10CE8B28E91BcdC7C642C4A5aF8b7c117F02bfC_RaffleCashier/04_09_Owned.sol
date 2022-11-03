// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract Owned {
    address public owner;

    event LogActualOwner(address sender, address oldOwner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner)
        internal
        onlyOwner
        returns (bool success)
    {
        require(
            newOwner != address(0x0),
            "You are not the owner of the contract."
        );
        owner = newOwner;
        emit LogActualOwner(msg.sender, owner, newOwner);
        return true;
    }
}
