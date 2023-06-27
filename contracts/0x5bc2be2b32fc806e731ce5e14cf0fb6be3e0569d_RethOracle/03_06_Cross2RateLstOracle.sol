// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../LstOracle.sol";

// get price based on cross rate from priceFeed1 to priceFeed2
abstract contract Cross2RateLstOracle is LstOracle {

    AggregatorV3Interface internal priceFeed1; // price feed of LST (ex. rETH/ETH)
    AggregatorV3Interface internal priceFeed2; // price feed of staked token (ex. ETH/USDT)

    function __Cross2RateLstOracle__init(AggregatorV3Interface _priceFeed1, AggregatorV3Interface _priceFeed2) internal onlyInitializing {
        priceFeed1 = _priceFeed1;
        priceFeed2 = _priceFeed2;
    }

    function _peekLstPrice() internal override view returns (uint256, bool) {
        (
        /*uint80 roundID*/,
        int price1,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed1.latestRoundData();
        if (price1 < 0) {
            return (0, false);
        }

        (
        /*uint80 roundID*/,
        int price2,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed2.latestRoundData();
        if (price2 < 0) {
            return (0, false);
        }

        uint256 price = uint(price1) * uint(price2) * 10**masterVault.decimals() / 10**(priceFeed1.decimals() + priceFeed2.decimals());

        return (price, true);
    }
}