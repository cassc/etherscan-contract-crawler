// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/mixins/nftDropMarket/NFTDropMarketCore.sol";

contract $NFTDropMarketCore is NFTDropMarketCore {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}