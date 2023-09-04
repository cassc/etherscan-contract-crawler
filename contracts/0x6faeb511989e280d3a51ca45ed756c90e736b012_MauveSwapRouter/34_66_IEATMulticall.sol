// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title EAT compatible Multicall interface
/// @notice Enables calling multiple EAT-gated methods in a single call to the contract
interface IEATMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param v The v component of the signed EAT signature
    /// @param r The r component of the signed EAT signature
    /// @param s The s component of the signed EAT signature
    /// @param expiry The expiry of the signed EAT
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);
}