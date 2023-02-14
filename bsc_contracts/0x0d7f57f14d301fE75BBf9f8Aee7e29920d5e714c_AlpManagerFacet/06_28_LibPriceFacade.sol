// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibChainlinkPrice} from  "../libraries/LibChainlinkPrice.sol";

library LibPriceFacade {

    uint8 constant public PRICE_DECIMALS = 8;
    uint8 constant public USD_DECIMALS = 18;

    function getPrice(address token) internal view returns (uint256) {
        // Later change to take prices from Chainlink Oracle and Binance Oracle and AMM LP and aggregate them
        (uint256 price, uint8 decimals) = LibChainlinkPrice.getPriceFromChainlink(token);
        return decimals == PRICE_DECIMALS ? price : price * (10 ** PRICE_DECIMALS) / (10 ** decimals);
    }
}