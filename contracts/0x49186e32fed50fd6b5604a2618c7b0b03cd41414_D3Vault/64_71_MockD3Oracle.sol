/*

    Copyright 2021 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {InitializableOwnable} from "../DODOV3MM/lib/InitializableOwnable.sol";
import {ID3Oracle} from "../intf/ID3Oracle.sol";
import "../DODOV3MM/lib/DecimalMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct PriceSource {
    uint256 price; // price in USD
    bool isWhitelisted;
    uint256 priceTolerance;
    uint8 priceDecimal;
}

contract MockD3Oracle is ID3Oracle, InitializableOwnable {
    // originToken => priceSource
    mapping(address => PriceSource) public priceSources;

    function setPriceSource(address token, PriceSource calldata source) external onlyOwner {
        priceSources[token] = source;
        require(source.priceTolerance <= DecimalMath.ONE, "INVALID_PRICE_TOLERANCE");
    }

    // return 1e18 decimal
    function getPrice(address token) public view override returns (uint256) {
        return priceSources[token].price;
    }

    function getDec18Price(address token) public view override returns (uint256) {
        return priceSources[token].price;
    }

    function isFeasible(address token) external view override returns (bool) {
        return priceSources[token].isWhitelisted;
    }

    // given the amount of fromToken, how much toToken can return at most
    function getMaxReceive(address fromToken, address toToken, uint256 fromAmount) external view returns (uint256) {
        uint256 fromTlr = priceSources[fromToken].priceTolerance;
        uint256 toTlr = priceSources[toToken].priceTolerance;

        return DecimalMath.div((fromAmount * getDec18Price(fromToken)) / getDec18Price(toToken), DecimalMath.mul(fromTlr, toTlr));
    }

    function getOriginalPrice(address token) public view override returns (uint256 price, uint8 priceDecimal) {
        return (getPrice(token), 8);
    }

    function testSuccess() public {}
}