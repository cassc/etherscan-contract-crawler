// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


contract RequestIdChecker {
    
    ///
    mapping(bytes32 => bool) public checks;
    /// 
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "RequestIdChecker: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function check(bytes32 id) public onlyOwner returns (bool) {
        if (checks[id] == false) {
            checks[id] = true;
            return true;
        }
        return false;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }
}