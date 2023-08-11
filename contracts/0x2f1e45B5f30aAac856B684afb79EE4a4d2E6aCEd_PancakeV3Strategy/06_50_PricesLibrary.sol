// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../ChainlinkPriceFeedAggregator.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @author YLDR <[email protected]>
library PricesLibrary {
    function getUSDPrice(ChainlinkPriceFeedAggregator oracle, address asset) internal view returns (uint256) {
        return oracle.getRate(asset);
    }

    function convertToUSD(ChainlinkPriceFeedAggregator oracle, address asset, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * oracle.getRate(asset)) / 10 ** IERC20Metadata(asset).decimals();
    }

    function convertFromUSD(ChainlinkPriceFeedAggregator oracle, uint256 usdAmount, address toAsset)
        internal
        view
        returns (uint256)
    {
        return usdAmount * 10 ** IERC20Metadata(toAsset).decimals() / oracle.getRate(toAsset);
    }

    function convert(ChainlinkPriceFeedAggregator oracle, address from, address to, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return convertFromUSD(oracle, convertToUSD(oracle, from, amount), to);
    }
}