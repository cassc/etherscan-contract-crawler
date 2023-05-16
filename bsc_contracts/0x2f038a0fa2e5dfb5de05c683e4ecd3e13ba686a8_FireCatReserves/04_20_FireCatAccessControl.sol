// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";


abstract contract FireCatAccessControl is AccessControlUpgradeable {
    // super administrator
    bytes32 public constant SUPER_ADMINISTRATOR = bytes32(keccak256(abi.encodePacked("MPI_SUPER_ADMINISTRATOR")));

    // market administrator
    bytes32 public constant SAFE_ADMIN = bytes32(keccak256(abi.encodePacked("Safe_Admin")));

    // data administrator
    bytes32 public constant DATA_ADMIN = bytes32(keccak256(abi.encodePacked("Data_Admin")));

    // fireCatVault contract
    bytes32 public constant FIRECAT_VAULT = bytes32(keccak256(abi.encodePacked("FireCat_Vault")));

    // fireCatGate contract
    bytes32 public constant FIRECAT_GATE = bytes32(keccak256(abi.encodePacked("FireCat_Gate")));

}