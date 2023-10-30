// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/interfaces/internal/INFTDropCollectionInitializer.sol";

abstract contract $INFTDropCollectionInitializer is INFTDropCollectionInitializer {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}