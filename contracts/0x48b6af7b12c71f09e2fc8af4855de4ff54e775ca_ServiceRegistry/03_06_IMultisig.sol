// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @dev Generic multisig.
interface IMultisig {
    /// @dev Creates a multisig.
    /// @param owners Set of multisig owners.
    /// @param threshold Number of required confirmations for a multisig transaction.
    /// @param data Packed data related to the creation of a chosen multisig.
    /// @return multisig Address of a created multisig.
    function create(
        address[] memory owners,
        uint256 threshold,
        bytes memory data
    ) external returns (address multisig);
}