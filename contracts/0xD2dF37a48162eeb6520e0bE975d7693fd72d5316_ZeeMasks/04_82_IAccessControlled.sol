// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice Access Control List contract interface.
interface IAccessControlled {
    /// @notice Get the ACL contract address.
    /// @return The ACL contract address.
    function getACL() external view returns (address);
}