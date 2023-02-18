// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IAggregatorV3 } from "../interfaces/IAggregatorV3.sol";
import { FixedPointMathLib } from "../libraries/FixedPointMathLib.sol";

abstract contract ChainLinkPriceOracle {
    using FixedPointMathLib for uint256;

    event SetPriceFeeds(address token, address priceFeed);
    event SetTokenPrice(address token, uint256 price);

    mapping(address => IAggregatorV3) internal _priceFeeds;
    mapping(address => uint256) internal _tokenPrices;

    function getPrice(address token) external view returns (uint256) {
        return _getPrice(token);
    }

    function _getPrice(address token) internal view returns (uint256) {
        IAggregatorV3 priceFeed = _priceFeeds[token];
        if (priceFeed != IAggregatorV3(address(0))) {
            (, int256 price, , , ) = _priceFeeds[token].latestRoundData();
            return uint256(price * 1e10);
        }
        return _tokenPrices[token];
    }

    function _getTokenAmountDown(address token, uint256 usdAmount) internal view returns (uint256) {
        uint256 price = _getPrice(token);
        return usdAmount.mulDivDown(1 ether, price);
    }

    function _getTokenAmountUp(address token, uint256 usdAmount) internal view returns (uint256) {
        uint256 price = _getPrice(token);
        return usdAmount.mulDivUp(1 ether, price);
    }

    function _getUsdAmount(address token, uint256 amount) internal view returns (uint256) {
        uint256 price = _getPrice(token);
        return (amount * price) / 1 ether;
    }

    function _setPriceFeeds(address token_, address priceFeed_) internal {
        _priceFeeds[token_] = IAggregatorV3(priceFeed_);
        emit SetPriceFeeds(token_, priceFeed_);
    }

    function _setTokenPrice(address token_, uint256 tokenPrice_) internal {
        _tokenPrices[token_] = tokenPrice_;
        emit SetTokenPrice(token_, tokenPrice_);
    }

    uint256[48] private __gap;
}