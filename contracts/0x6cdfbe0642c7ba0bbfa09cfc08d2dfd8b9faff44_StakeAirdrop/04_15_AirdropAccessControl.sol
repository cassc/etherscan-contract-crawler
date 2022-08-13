// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";


abstract contract AirdropAccessControl is AccessControlUpgradeable {
    // market administrator
    bytes32 public constant MARKET_ADMIN = bytes32(keccak256(abi.encodePacked("Market_Admin")));

    // data administrator
    bytes32 public constant DATA_ADMIN = bytes32(keccak256(abi.encodePacked("Data_Admin")));

}