// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract OnlyContract {
    address isContract;

    constructor(address _contract) {
        isContract = _contract;
    }

    modifier onlyContract() {
        require(msg.sender == isContract, "You are not allowed to call this function.");
        _;
    }
}