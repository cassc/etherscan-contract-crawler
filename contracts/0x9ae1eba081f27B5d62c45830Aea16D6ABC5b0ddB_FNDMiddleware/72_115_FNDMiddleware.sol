// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/FNDMiddleware.sol";

contract $FNDMiddleware is FNDMiddleware {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address payable _market, address payable _nftDropMarket, address payable _feth) FNDMiddleware(_market, _nftDropMarket, _feth) {}

    receive() external payable {}
}