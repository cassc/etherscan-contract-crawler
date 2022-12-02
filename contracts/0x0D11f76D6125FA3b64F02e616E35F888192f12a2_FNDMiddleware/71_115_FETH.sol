// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/FETH.sol";

contract $FETH is FETH {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _foundationMarket, address payable _foundationDropMarket, uint256 _lockupDuration) FETH(_foundationMarket, _foundationDropMarket, _lockupDuration) {}
}