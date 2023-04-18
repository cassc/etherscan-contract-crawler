// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * This is an extension of the original StorageBase contract, allowing for a second ownerHelper address to access
 * owner-restricted functions
 */

contract StorageBaseExtension {
    address payable internal owner;
    address payable internal ownerHelper;

    modifier requireOwner() {
        require(
            msg.sender == address(owner) || msg.sender == address(ownerHelper),
            'StorageBase: Not owner or ownerHelper!'
        );
        _;
    }

    constructor(address _ownerHelper) {
        owner = payable(msg.sender);
        ownerHelper = payable(_ownerHelper);
    }

    function setOwner(address _newOwner) external requireOwner {
        owner = payable(_newOwner);
    }

    function setOwnerHelper(address _newOwnerHelper) external requireOwner {
        ownerHelper = payable(_newOwnerHelper);
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}