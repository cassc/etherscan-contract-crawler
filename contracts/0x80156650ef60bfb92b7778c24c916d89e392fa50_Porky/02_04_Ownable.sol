// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Ownable {
    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renouncedOwnership() public virtual onlyOwner {
        _owner = address(0);
    }
}