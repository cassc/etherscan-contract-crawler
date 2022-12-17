// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";


abstract contract FireCatAccessControl is AccessControlUpgradeable {
    // market administrator
    bytes32 public constant SAFE_ADMIN = bytes32(keccak256(abi.encodePacked("Safe_Admin")));

    // data administrator
    bytes32 public constant DATA_ADMIN = bytes32(keccak256(abi.encodePacked("Data_Admin")));
}