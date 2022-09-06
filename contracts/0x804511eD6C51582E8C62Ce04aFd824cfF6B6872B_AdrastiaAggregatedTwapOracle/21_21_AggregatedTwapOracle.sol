//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/oracles/AggregatedOracle.sol";

import "../AdrastiaVersioning.sol";

contract AdrastiaAggregatedTwapOracle is AdrastiaVersioning, AggregatedOracle {
    string public name;

    constructor(
        string memory name_,
        string memory quoteTokenName_,
        address quoteTokenAddress_,
        string memory quoteTokenSymbol_,
        uint8 quoteTokenDecimals_,
        address[] memory oracles_,
        TokenSpecificOracle[] memory tokenSpecificOracles_,
        uint256 period_,
        uint256 minimumTokenLiquidityValue_,
        uint256 minimumQuoteTokenLiquidity_
    )
        AggregatedOracle(
            quoteTokenName_,
            quoteTokenAddress_,
            quoteTokenSymbol_,
            quoteTokenDecimals_,
            oracles_,
            tokenSpecificOracles_,
            period_,
            minimumTokenLiquidityValue_,
            minimumQuoteTokenLiquidity_
        )
    {
        name = name_;
    }
}