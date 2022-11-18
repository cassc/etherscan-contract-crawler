// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title Cake access control
/// @author landakram
/// @notice This contact centralizes contract-to-contract access control using a simple
/// access-control list. There are two types of actors: operators and admins. Operators
/// are callers involved in a regular end-user tx. This would likely be another Goldfinch
/// contract for which the current contract is a dependency. Admins are callers allowed
/// for specific admin actions (like changing parameters, topping up funds, etc.).
interface IAccessControl {
  error RequiresAdmin(address resource, address accessor);
  error ZeroAddress();

  event AdminSet(address indexed resource, address indexed admin);

  /// @notice Set an admin for a given resource
  /// @param resource An address which with `admin` should be allowed to administer
  /// @param admin An address which should be allowed to administer `resource`
  /// @dev This method is only callable by the super-admin (the admin of this AccessControl
  ///   contract)
  function setAdmin(address resource, address admin) external;

  /// @notice Require a valid admin for a given resource
  /// @param resource An address that `accessor` is attempting to access
  /// @param accessor An address on which to assert access control checks
  /// @dev This method reverts when `accessor` is not a valid admin
  function requireAdmin(address resource, address accessor) external view;

  /// @notice Require a super-admin. A super-admin is an admin of this AccessControl contract.
  /// @param accessor An address on which to assert access control checks
  /// @dev This method reverts when `accessor` is not a valid super-admin
  function requireSuperAdmin(address accessor) external view;
}