//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Wallet hash interface
/// @author Amit Molek
interface IWalletHash {
    /// @dev Emitted on approved hash
    /// @param hash the approved hash
    event ApprovedHash(bytes32 hash);

    /// @dev Emitted on revoked hash
    /// @param hash the revoked hash
    event RevokedHash(bytes32 hash);

    /// @return true, if the hash is approved
    function isHashApproved(bytes32 hash) external view returns (bool);

    /// @return `hash`'s deadline
    function hashDeadline(bytes32 hash) external view returns (uint256);

    /// @notice Approves hash
    /// @param hash to be approved
    /// @param signatures a set of member's EIP191 signatures on `hash`
    /// @dev Emits `ApprovedHash`
    function approveHash(bytes32 hash, bytes[] memory signatures) external;

    /// @notice Revoke approved hash
    /// @param hash to be revoked
    /// @param signatures a set of member's EIP191 signatures on `hash`
    /// @dev Emits `RevokedHash`
    function revokeHash(bytes32 hash, bytes[] memory signatures) external;
}