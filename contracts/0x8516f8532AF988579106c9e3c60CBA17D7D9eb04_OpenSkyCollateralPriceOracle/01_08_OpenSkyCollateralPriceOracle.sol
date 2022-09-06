// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOpenSkyCollateralPriceOracle.sol';
import './interfaces/IOpenSkySettings.sol';
import './libraries/helpers/Errors.sol';
import './interfaces/IOpenSkyPriceAggregator.sol';

/**
 * @title OpenSkyCollateralPriceOracle contract
 * @author OpenSky Labs
 * @dev Implements logics of the collateral price oracle for the OpenSky protocol
 **/
contract OpenSkyCollateralPriceOracle is Ownable, IOpenSkyCollateralPriceOracle {
    IOpenSkySettings public immutable SETTINGS;

    mapping(address => NFTPriceData[]) public nftPriceFeedMap;

    IOpenSkyPriceAggregator private _priceAggregator;

    uint256 internal _roundInterval;
    uint256 internal _timeInterval;

    struct NFTPriceData {
        uint256 roundId;
        uint256 price;
        uint256 timestamp;
        uint256 cumulativePrice;
    }

    constructor(IOpenSkySettings settings, IOpenSkyPriceAggregator priceAggregator) Ownable() {
        SETTINGS = settings;
        _priceAggregator = priceAggregator;
    }

    function setPriceAggregator(address priceAggregator) external onlyOwner {
        _priceAggregator = IOpenSkyPriceAggregator(priceAggregator);
        emit SetPriceAggregator(_msgSender(), priceAggregator);
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function updatePrice(
        address nftAddress,
        uint256 price,
        uint256 timestamp
    ) public override onlyOwner {
        NFTPriceData[] storage prices = nftPriceFeedMap[nftAddress];
        NFTPriceData memory latestPriceData = prices.length > 0
            ? prices[prices.length - 1]
            : NFTPriceData({roundId: 0, price: 0, timestamp: 0, cumulativePrice: 0});
        require(timestamp > latestPriceData.timestamp, Errors.PRICE_ORACLE_INCORRECT_TIMESTAMP);
        uint256 cumulativePrice = latestPriceData.timestamp > 0
            ? latestPriceData.cumulativePrice + (timestamp - latestPriceData.timestamp) * latestPriceData.price
            : 0;
        uint256 roundId = latestPriceData.roundId + 1;
        NFTPriceData memory data = NFTPriceData({
            price: price,
            timestamp: timestamp,
            roundId: roundId,
            cumulativePrice: cumulativePrice
        });
        prices.push(data);

        emit UpdatePrice(nftAddress, price, timestamp, roundId);
    }

    /**
     * @notice Updates floor prices of NFT collections
     * @param nftAddresses Addresses of NFT collections
     * @param prices Floor prices of NFT collections
     * @param timestamp The timestamp when prices happened
     **/
    function updatePrices(
        address[] memory nftAddresses,
        uint256[] memory prices,
        uint256 timestamp
    ) external onlyOwner {
        require(nftAddresses.length == prices.length, Errors.PRICE_ORACLE_PARAMS_ERROR);
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            updatePrice(nftAddresses[i], prices[i], timestamp);
        }
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function setRoundInterval(uint256 roundInterval) external override onlyOwner {
        _roundInterval = roundInterval;
        emit SetRoundInterval(_msgSender(), roundInterval);
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function setTimeInterval(uint256 timeInterval) external override onlyOwner {
        _timeInterval = timeInterval;
        emit SetTimeInterval(_msgSender(), timeInterval);
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function getPrice(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view override returns (uint256) {
        if (!SETTINGS.inWhitelist(reserveId, nftAddress)) {
            return 0;
        }
        if (address(_priceAggregator) == address(0)) {
            return _getPrice(nftAddress);
        } else {
            uint256 price = _priceAggregator.getAssetPrice(nftAddress);
            return price > 0 ? price : _getPrice(nftAddress);
        }
    }

    function _getPrice(address nftAddress) internal view returns (uint256) {
        if (_timeInterval > 0) {
            return getTwapPriceByTimeInterval(nftAddress, _timeInterval);
        } else {
            return getTwapPriceByRoundInterval(nftAddress, _roundInterval);
        }
    }

    /**
     * @notice Returns the TWAP price of NFT during the particular round interval
     * @param nftAddress The address of the NFT
     * @param roundInterval The round interval
     * @return The price of the NFT
     **/
    function getTwapPriceByRoundInterval(address nftAddress, uint256 roundInterval) public view returns (uint256) {
        uint256 priceFeedLength = getPriceFeedLength(nftAddress);
        if (priceFeedLength == 0) {
            return 0;
        }
        uint256 currentRound = priceFeedLength - 1;
        NFTPriceData memory currentPriceData = nftPriceFeedMap[nftAddress][currentRound];
        if (roundInterval == 0 || priceFeedLength == 1) {
            return currentPriceData.price;
        }
        uint256 previousRound = currentRound > roundInterval ? currentRound - roundInterval : 0;
        NFTPriceData memory previousPriceData = nftPriceFeedMap[nftAddress][previousRound];
        return
            (currentPriceData.price *
                (block.timestamp - currentPriceData.timestamp) +
                currentPriceData.cumulativePrice -
                previousPriceData.cumulativePrice) / (block.timestamp - previousPriceData.timestamp);
    }

    /**
     * @notice Returns the TWAP price of NFT during the particular time interval
     * @param nftAddress The address of the NFT
     * @param timeInterval The time interval
     * @return The price of the NFT
     **/
    function getTwapPriceByTimeInterval(address nftAddress, uint256 timeInterval) public view returns (uint256) {
        uint256 priceFeedLength = getPriceFeedLength(nftAddress);
        if (priceFeedLength == 0) {
            return 0;
        }

        NFTPriceData memory currentPriceData = nftPriceFeedMap[nftAddress][priceFeedLength - 1];
        uint256 baseTimestamp = block.timestamp - timeInterval;

        if (currentPriceData.timestamp <= baseTimestamp) {
            return currentPriceData.price;
        }

        NFTPriceData memory firstPriceData = nftPriceFeedMap[nftAddress][0];
        if (firstPriceData.timestamp >= baseTimestamp) {
            return
                (currentPriceData.price *
                    (block.timestamp - currentPriceData.timestamp) +
                    (currentPriceData.cumulativePrice - firstPriceData.cumulativePrice)) /
                (block.timestamp - firstPriceData.timestamp);
        }

        uint256 roundIndex = priceFeedLength - 1;
        NFTPriceData storage basePriceData = nftPriceFeedMap[nftAddress][roundIndex];

        while (roundIndex > 0 && basePriceData.timestamp > baseTimestamp) {
            basePriceData = nftPriceFeedMap[nftAddress][--roundIndex];
        }

        uint256 cumulativePrice = currentPriceData.price *
            (block.timestamp - currentPriceData.timestamp) +
            (currentPriceData.cumulativePrice - basePriceData.cumulativePrice);
        cumulativePrice -= basePriceData.price * (baseTimestamp - basePriceData.timestamp);
        return cumulativePrice / timeInterval;
    }

    /**
     * @notice Returns the data of the particular price feed
     * @param nftAddress The address of the NFT
     * @param index The index of the feed
     * @return The data of the price feed
     **/
    function getPriceData(address nftAddress, uint256 index) external view returns (NFTPriceData memory) {
        return nftPriceFeedMap[nftAddress][index];
    }

    /**
     * @notice Returns the count of price feeds about the particular NFT
     * @param nftAddress The address of the NFT
     * @return length The count of price feeds
     **/
    function getPriceFeedLength(address nftAddress) public view returns (uint256 length) {
        return nftPriceFeedMap[nftAddress].length;
    }

    /**
     * @notice Returns the latest round id of the particular NFT
     * @param nftAddress The address of the NFT
     * @return The latest round id
     **/
    function getLatestRoundId(address nftAddress) external view returns (uint256) {
        uint256 len = getPriceFeedLength(nftAddress);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeedMap[nftAddress][len - 1].roundId;
    }
}