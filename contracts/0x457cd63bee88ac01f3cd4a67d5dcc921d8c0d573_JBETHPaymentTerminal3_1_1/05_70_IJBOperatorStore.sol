// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {JBOperatorData} from './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address operator,
    address account,
    uint256 domain
  ) external view returns (uint256);

  function hasPermission(
    address operator,
    address account,
    uint256 domain,
    uint256 permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address operator,
    address account,
    uint256 domain,
    uint256[] calldata permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata operatorData) external;

  function setOperators(JBOperatorData[] calldata operatorData) external;
}