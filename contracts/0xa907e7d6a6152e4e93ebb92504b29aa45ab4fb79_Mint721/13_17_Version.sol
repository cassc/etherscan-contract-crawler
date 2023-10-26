// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

abstract contract Version {
    /// @notice The version of the contract.
    uint32 public immutable contractVersion;

    constructor(uint32 _contractVersion) {
        contractVersion = _contractVersion;
    }
}