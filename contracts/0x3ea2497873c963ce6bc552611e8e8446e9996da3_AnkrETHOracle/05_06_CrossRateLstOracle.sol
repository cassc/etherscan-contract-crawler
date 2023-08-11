// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../LstOracle.sol";

// get price using conversion of lst to value and using value price feed to USD
abstract contract CrossRateLstOracle is LstOracle {

    AggregatorV3Interface internal priceFeed; // price feed of value (ex. ETH/USD)
    address internal lsToken; // liquid staked token (ex. wstETH, ankrETH)
    IRatioAdapter internal ratioAdapter; // ratio adapter for conversion

    function __CrossRateLstOracle__init(AggregatorV3Interface _aggregatorAddress, address _lsToken, IRatioAdapter _ratioAdapter) internal onlyInitializing {
        lsToken = _lsToken;
        ratioAdapter = _ratioAdapter;
        priceFeed = _aggregatorAddress;
    }

    function _peekLstPrice() internal override view returns (uint256, bool) {
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        if (price < 0) {
            return (0, false);
        }
        // Get Staked Token equivalent to 1 LST and multiply with Staked Token price
        uint256 value = ratioAdapter.toValue(lsToken, 1e18);
        uint256 lsTokenPrice = value * uint(price) / 10**priceFeed.decimals();
        return (lsTokenPrice, true);
    }
}