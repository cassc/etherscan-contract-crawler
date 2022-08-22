//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Oracle is CoreRef {
    using SignedSafeMath for int256;
    using SafeMath for uint256;


    struct Feed {
        address aggregator;
        uint8 baseDecimals;
    }
    // token address => Feed
    mapping(address => Feed) public feeds;

    constructor(
        address _core,
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) public CoreRef(_core) {
        _setFeeds(_tokens, _baseDecimals, _aggregators);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(address token) public view returns (int256 price) {
        Feed storage feed = feeds[token];
        require(feed.aggregator != address(0), "Oracle:: price feed does not exist");
        (, int256 price, , , ) = AggregatorV3Interface(feed.aggregator).latestRoundData();
        return price;
    }

    function getBaseDecimals(address token) public view returns (uint8) {
        Feed storage feed = feeds[token];
        return feed.baseDecimals;
    }

    function getResponseDecimals(address token) public view returns(uint8) {
        Feed storage feed = feeds[token];
        return AggregatorV3Interface(feed.aggregator).decimals();
    }

    function scalePrice(
        uint256 _price,
        uint8 _quoteDecimals,
        uint8 _baseDecimals
    ) public pure returns (uint256) {
        if (_quoteDecimals < _baseDecimals) {
            return _price.mul(uint256(10**uint256(_baseDecimals - _quoteDecimals)));
        } else if (_quoteDecimals > _baseDecimals) {
            return _price.div(uint256(10**uint256(_quoteDecimals - _baseDecimals)));
        }
        return _price;
    }

    function setFeeds(
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) public onlyGovernor {
        _setFeeds(_tokens, _baseDecimals, _aggregators);
    }

    function _setFeeds(
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            feeds[_tokens[i]] = Feed(_aggregators[i], _baseDecimals[i]);
        }
    }
}