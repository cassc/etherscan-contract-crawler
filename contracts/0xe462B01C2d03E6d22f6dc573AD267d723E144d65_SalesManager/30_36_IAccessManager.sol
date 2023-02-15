// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

/// @title Interface for the AccessManager Smart Contract
/// @author Github: Labrys-Group
/// @notice Utilised to house all authorised accounts within the IMPT contract eco-system
interface IAccessManager is IAccessControlEnumerable {
  struct ConstructorParams {
    address superUser;
  }

  /// @dev throws when the array lengths do not match when bulk granting roles
  error ArrayLengthMismatch();

/// @dev used to grant roles to specific addresses in bulk
/// @param _roles an array of roles encoded into bytes
/// @param _addresses the addresses to grant the roles to, in order of roles listed
  function bulkGrantRoles(
    bytes32[] calldata _roles,
    address[] calldata _addresses
  ) external;

/// @dev sets the admin role for approved DEX and Sales Managers
  function transferDEXRoleAdmin() external;
}