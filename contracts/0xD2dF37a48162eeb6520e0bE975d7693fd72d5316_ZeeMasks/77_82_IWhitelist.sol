// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/// @notice Interface that public whitelist interaction.
interface IWhitelist {
    /// @notice Set the merkle root for Whitelist validation.
    /// @param merkleRoot The merkle root.
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external;

    /// @notice Check if the user has been whitelisted either through Merkle Root or manually.
    function isUserWhitelisted(address account, bytes32[] memory proof) external returns (bool);

    /// @notice Get the Whitelist specific merkle root.
    /// @return bytes32 merkle root
    function getWhitelistMerkleRoot() external returns (bytes32);
}