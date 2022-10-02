// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../ProviderAwareOracle.sol";

contract ChainlinkPriceOracle is ProviderAwareOracle {

    uint private constant MIN_TIME = 60 minutes;
    
    // If comparing to WETH, will be left as address(0)
    address public BASE_PRICE_FEED;

    uint8 public decimals = 18;

    mapping(address => address) public priceFeed; // token => chainlink price feed

    event UpdateValues(address indexed feed);
    event OutputDecimalsUpdated(uint8 _old, uint8 _new);
    event SetPriceFeed(address indexed token, address indexed feed);

    constructor(address _provider, address _base_price_feed) ProviderAwareOracle(_provider) {
        BASE_PRICE_FEED = _base_price_feed;
    }

    function setPriceFeed(address _token, address _feed) external onlyOwner {
        priceFeed[_token] = _feed;

        emit SetPriceFeed(_token, _feed);
    }

    function getSafePrice(address _token) public view returns (uint256 _amountOut) {
        return getCurrentPrice(_token);
    }

    function getCurrentPrice(address _token) public view returns (uint256 _amountOut) {
        require(priceFeed[_token] != address(0), "UNSUPPORTED");

        _amountOut = _divide(
            _feedPrice(priceFeed[_token]),
            _feedPrice(BASE_PRICE_FEED),
            decimals
        );
    }

    function setOutputDecimals(uint8 _decimals) public onlyOwner {
        uint8 _old = _decimals;
        decimals = _decimals;
        emit OutputDecimalsUpdated(_old, _decimals);
    }

    function updateSafePrice(address _feed) public returns (uint256 _amountOut) {
        emit UpdateValues(_feed); // keeps this mutable so it matches the interface

        return getCurrentPrice(_feed);
    }

    /****** INTERNAL METHODS ******/

    /**
     * @dev internal method that does quick division using the set precision
     */
    function _divide(
        uint256 a,
        uint256 b,
        uint8 precision
    ) internal pure returns (uint256) {
        return (a * (10**precision)) / b;
    }

    function _feedPrice(address _feed) internal view returns (uint256 latestUSD) {

        /// To allow for TOKEN-ETH feeds on one oracle, TOKEN-USD feeds on another
        if(_feed == address(0)) {
            return PRECISION;
        }

        (uint80 roundID, int256 answer, uint256 startedAt, uint256 timestamp, uint80 answeredInRound) = AggregatorV3Interface(_feed).latestRoundData();

        require(answer > 0, 'ER045');
        require(timestamp != 0, 'ER046');
        require(answeredInRound >= roundID, "ER047");

        // difference between when started and returned needs to be less than 60-minutes
        require(timestamp - startedAt < MIN_TIME, "E113");

        return uint256(answer);
    }
}