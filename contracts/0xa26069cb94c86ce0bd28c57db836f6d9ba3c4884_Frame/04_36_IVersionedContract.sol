// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVersionedContract {
    /**
     * @notice Returns the storage, major, minor, and patch version of the contract.
     * @return The storage, major, minor, and patch version of the contract.
     */
    function getVersionNumber()
        external
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}