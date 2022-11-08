// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Administration is AccessControlEnumerable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant RESTRICTOR_ROLE = keccak256("RESTRICTOR_ROLE");
    bytes32 public constant TRANSFER_LIMIT_SETTER = keccak256("TRANSFER_LIMIT_SETTER");
    bytes32 public constant TRANSACTION_FEE_SETTER = keccak256("TRANSACTION_FEE_SETTER");

}