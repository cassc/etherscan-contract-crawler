// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member owner if set then the contract belongs to this static address.
  @member projectId if set then the contract belongs to whatever address owns the project
  @member permissionIndex the permission that is required on the specified project to act as the owner for this contract.
 */
struct JBOwner {
    address owner;
    uint88 projectId;
    uint8 permissionIndex;
}