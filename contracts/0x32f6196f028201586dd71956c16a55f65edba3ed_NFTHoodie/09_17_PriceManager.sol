// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IERC20.sol";

abstract contract PriceManager is Ownable {
    uint256 public priceUsd; // Usd price with to decimals
    mapping(address => uint256) private _upgradePrice;
    mapping(address => bool) private _isStablecoin;

    error TokenIsStablecoin();
    error PriceNotSet();

    AggregatorV3Interface internal priceFeed;

    constructor(uint256 priceUsd_, address feedAddress) {
        priceFeed = AggregatorV3Interface(feedAddress);
        priceUsd = priceUsd_;
    }

    /**
     * Returns the latest price
     * 123.45 $ => 12345
     */
    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price / 1e6);
    }

    function calcNativePrice(uint256 _priceUsd, uint8 decimals) public view returns (uint256) {
        return (_priceUsd * 10**decimals) / getLatestPrice();
    }

    function getTotalPrice(address token, uint256 amount) public view returns (uint256 total) {
        if (token == address(0x0)) {
            total = ((calcNativePrice(priceUsd, 18) * amount) / 10e12) * 10e12; // Rounded Price
        } else if (_isStablecoin[token]) {
            total = priceUsd * 10**(IERC20(token).decimals() - 2) * amount;
        } else if (_upgradePrice[token] > 0) {
            total = _upgradePrice[token] * amount;
        } else {
            revert PriceNotSet();
        }
    }

    function addStablecoin(address token) public onlyOwner {
        _isStablecoin[token] = true;
    }

    function removeStablecoin(address token) public onlyOwner {
        _isStablecoin[token] = false;
    }

    function setPrice(uint256 price) public onlyOwner {
        priceUsd = price;
    }

    function setTokenPrice(address token, uint256 price) public onlyOwner {
        if(_isStablecoin[token]) {
            revert TokenIsStablecoin();
        }
        _upgradePrice[token] = price;
    }

    function getTokenPrice(address token) public view returns (uint256) {
       return _upgradePrice[token];
    }
}