// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/dependencies/tokens/IERC20Approve.sol";

abstract contract $IERC20Approve is IERC20Approve {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}