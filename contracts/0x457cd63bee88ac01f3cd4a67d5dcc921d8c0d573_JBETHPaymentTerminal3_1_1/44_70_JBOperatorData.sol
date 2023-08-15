// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom:member operator The address of the operator.
/// @custom:member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
/// @custom:member permissionIndexes The indexes of the permissions the operator is being given.
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}