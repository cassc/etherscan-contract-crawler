// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IDepositNative {
    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param depositor Address of account making the deposit in the Bridge contract.
    /// @param data Consists of additional data needed for a specific deposit.
    function depositNative(
        bytes32 resourceID,
        address depositor,
        bytes calldata data
    ) external payable returns (bytes memory);
}