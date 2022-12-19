//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Multisig Governance interface
/// @author Amit Molek
interface IGovernance {
    /// @notice Verify the given hash using the governance rules
    /// @param hash the hash you want to verify
    /// @param signatures the member's signatures of the given hash
    /// @return true, if all the hash is verified
    function verifyHash(bytes32 hash, bytes[] memory signatures)
        external
        view
        returns (bool);
}