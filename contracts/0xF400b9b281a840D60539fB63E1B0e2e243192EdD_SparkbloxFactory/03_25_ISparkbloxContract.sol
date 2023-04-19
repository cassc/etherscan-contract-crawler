// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISparkbloxContract {
    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32);

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8);
}