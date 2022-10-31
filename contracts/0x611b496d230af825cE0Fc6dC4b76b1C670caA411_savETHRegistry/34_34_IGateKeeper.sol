pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

/// @notice Required interface for gate keeping whether a member is allowed in a Stakehouse registry, brand or anything else for that matter
interface IGateKeeper {
    /// @notice Called by the Stakehouse registry or Brand Central before adding a member to a house or brand
    /// @param _blsPubKey BLS public key of the KNOT being added to the Stakehouse registry or brand
    function isMemberPermitted(bytes calldata _blsPubKey) external view returns (bool);
}