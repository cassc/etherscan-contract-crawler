// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @notice A registry contract that stores call permissions
/// @dev Used by Sodium wallets to check if an external call is safe during `execute` calls
/// Each call is defined by an address and a function signature
interface ISodiumRegistry {
    /// @notice Used by Registry owner to set permission for one or more calls
    /// @param contractAddresses The in-order addresses to which the calls in question are made
    /// @param functionSignatures The in-order signatures of each call
    /// @param permissions_ The in-order permissions to be assigned to the calls
    function setCallPermissions(
        address[] calldata contractAddresses,
        bytes4[] calldata functionSignatures,
        bool[] calldata permissions_
    ) external;

    /// @notice Used to obtain call permission
    /// @param contractAddress The address of the contract to which the calls are made
    /// @param functionSignature The address of the contract to which the calls are made
    /// @return Whether walllets are permitted to make calls with input address & signature combination
    function getCallPermission(address contractAddress, bytes4 functionSignature) external view returns (bool);
}