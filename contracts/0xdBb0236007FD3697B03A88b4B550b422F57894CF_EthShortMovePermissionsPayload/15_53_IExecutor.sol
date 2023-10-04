// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IExecutor {
  function setPendingAdmin(address newPendingAdmin) external;

  function getPendingAdmin() external view returns (address);

  function acceptAdmin() external;

  function getAdmin() external view returns (address);
}