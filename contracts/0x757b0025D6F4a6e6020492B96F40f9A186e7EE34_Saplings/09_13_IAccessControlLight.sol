// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAccessControlLight {
  error MissingRole();
  error NothingToDo();
  error NeedAtLeastOneAdmin();

  event RoleGranted(bytes32 indexed role, address indexed account);
  event RoleRevoked(bytes32 indexed role, address indexed account);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function hasRole(bytes32 role, address account) external view returns (bool);
  function grantRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function renounceRole(bytes32 role) external;
}