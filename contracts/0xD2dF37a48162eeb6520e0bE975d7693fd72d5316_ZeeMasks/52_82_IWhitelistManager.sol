// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/// @notice Interface that public whitelist interaction.
interface IWhitelistManager {
    /// @notice Thrown when attempting to enable the the merkle root validation without setting the merkle root prior..
    error MerkleRootNotSet();

    /// @notice Thrown when attempting to call a whitelist-protected method, whilst a user has not been whitelisted..
    error NotWhitelisted();

    /// @notice Emitted when the merkle root has been set.
    event MerkleRootSet(bytes32 merkleRoot);

    /// @notice Emitted when a user has been added to the whitelist manually.
    event AddedToWhitelist(address account);

    /// @notice Emitted when a user has been removed from the whitelist.
    event RemovedFromWhitelist(address account);

    struct WhitelistOverride {
        bool blocked;
        bool whitelisted;
    }

    /// @notice Set the merkle root for Whitelist validation.
    /// @param merkleRoot The merkle root.
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external;

    /// @notice Enable whitelist merkle root validation.
    /// @dev The whitelist merkle root needs to be set to enable this.
    function enableWhitelist() external;

    /// @notice Disables the whitelist merkle root validation.
    /// @dev The whitelist validation features needs to be enabled to call this.
    function disableWhitelist() external;

    /// @notice Check if the user has been whitelisted either through Merkle Root or manually.
    function isUserWhitelisted(address account, bytes32[] memory proof) external returns (bool);

    /// @notice Add user to the whitelist manually.
    function addUserToWhitelist(address account) external;

    /// @notice Remove user from the whitelist manually.
    function removeUserFromWhitelist(address account) external;

    /// @notice Get the Whitelist specific merkle root.
    /// @return bytes32 merkle root
    function getWhitelistMerkleRoot() external returns (bytes32);
}