// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IMSContract {
    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32);

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8);
}