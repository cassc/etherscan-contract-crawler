// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.9;

/// @title IClaimable
/// @author [email protected]
/// @notice Interface for getting count of claims

interface IClaimable {
    function addressClaimCount(address account) external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}