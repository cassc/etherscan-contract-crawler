//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Utils/Context.sol";

error NotAnOwner();

abstract contract Ownable is Context {
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    modifier onlyOwner() {
        if (isOwner(_msgSender()) != true) revert NotAnOwner();
        _;
    }
}