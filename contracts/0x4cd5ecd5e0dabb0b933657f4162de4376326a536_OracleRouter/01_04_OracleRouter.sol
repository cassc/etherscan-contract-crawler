// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Oracle set to retrieve the price of an asset in dollars with 8 decimals.
 * @dev If feed not exist admin can set a price fixed for the asset
 * @dev When adding a feed for a stablecoin asset, set the '_isStablecoin' variable to true
 *  to enable checking for stablecoins that cannot deviate in price by more than 30% from 1 USD.
 * @dev Use "setFeed(address _asset, address _feed, uint _priceAdmin, bool _isStablecoin)" to add a new asset.
 * @dev Use "price(address _asset)" to retrieve the price of an asset in USD with 8 decimal
 */
contract OracleRouter is Ownable {
    uint256 constant MIN_DRIFT = uint256(70000000);
    uint256 constant MAX_DRIFT = uint256(130000000);

    struct FeedStruct {
        address feedAddress;
        uint priceAdmin;
        uint heartbeat;
        bool isStablecoin;
    }
    mapping(address => FeedStruct) public assetToFeed;

    function setFeed(address _asset, address _feed, uint _priceAdmin, uint _heartbeat, bool _isStablecoin) external {
        require(_feed == address(0) || _priceAdmin == 0, "cannot set feed and priceAdmin at same time");
        assetToFeed[_asset].feedAddress = _feed;
        assetToFeed[_asset].priceAdmin = _priceAdmin;
        assetToFeed[_asset].heartbeat = _heartbeat;
        assetToFeed[_asset].isStablecoin = _isStablecoin;
    }

    /**
     * @dev The price feed contract to use for a particular asset and if is a stablecoin.
     * @param _asset address of the asset
     */
    function getFeed(address _asset) public view returns (address, uint, uint, bool) {
        return (assetToFeed[_asset].feedAddress, assetToFeed[_asset].priceAdmin, assetToFeed[_asset].heartbeat, assetToFeed[_asset].isStablecoin);
    }

    /**
     * @notice Returns the total price in 8 digit USD for a given asset.
     * @param _asset address of the asset
     * @return uint256 USD price of 1 of the asset, in 8 decimal fixed
     */
    function price(address _asset) external view virtual returns (uint, uint) {
        (address feed, uint priceAdmin, uint heartbeat, bool isStablecoin) = getFeed(_asset);
        if(feed == address(0)) {
            return (priceAdmin, 2);
        }
        (, int256 iPrice, uint startedAt, ,) = AggregatorV3Interface(feed).latestRoundData();
        uint8 decimals = AggregatorV3Interface(feed).decimals();
        require(verifyTimestampRound(startedAt, heartbeat), "feed price is not updated");
        uint256 priceRoundData = uint256(iPrice);
        if (isStablecoin) {
            require(priceRoundData <= MAX_DRIFT, "Oracle: Price exceeds max");
            require(priceRoundData >= MIN_DRIFT, "Oracle: Price under min");
        }
        return (priceRoundData, uint(decimals));
    }

    function verifyTimestampRound(uint _timestampRound, uint _heartbeat) public view returns (bool) {
        return (block.timestamp - _timestampRound) <= _heartbeat;
    }
}