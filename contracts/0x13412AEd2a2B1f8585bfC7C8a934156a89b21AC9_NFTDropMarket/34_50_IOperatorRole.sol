// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/internal/roles/IOperatorRole.sol";

abstract contract $IOperatorRole is IOperatorRole {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}