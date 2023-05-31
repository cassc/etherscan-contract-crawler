// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IClientBatchStorageAccess {
  function grantClientAccess(address newClient) external;

  function revokeClientAccess(address client) external;

  function acceptClientAccess(address grantingAddress) external;

  function addClient(address _address) external;

  function removeClient(address _address) external;
}