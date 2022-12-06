// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketPrivateSaleGap.sol";

contract $NFTMarketPrivateSaleGap is NFTMarketPrivateSaleGap {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}