// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'Not owner!');
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = payable(address(_newOwner));
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}