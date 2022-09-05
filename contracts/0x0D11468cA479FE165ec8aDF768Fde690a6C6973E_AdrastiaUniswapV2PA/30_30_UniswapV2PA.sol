//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-periphery/contracts/accumulators/proto/uniswap/ManagedUniswapV2PriceAccumulator.sol";

import "../AdrastiaVersioning.sol";

contract AdrastiaUniswapV2PA is AdrastiaVersioning, ManagedUniswapV2PriceAccumulator {
    string public name;

    constructor(
        string memory name_,
        address uniswapFactory_,
        bytes32 initCodeHash_,
        address quoteToken_,
        uint256 updateTheshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    )
        ManagedUniswapV2PriceAccumulator(
            uniswapFactory_,
            initCodeHash_,
            quoteToken_,
            updateTheshold_,
            minUpdateDelay_,
            maxUpdateDelay_
        )
    {
        name = name_;
    }
}