// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IOpenSkyPriceOracle
 * @author OpenSky Labs
 * @notice Defines the basic interface for a price oracle.
 **/
interface IOpenSkyCollateralPriceOracle {
    /**
     * @dev Emitted on setPriceAggregator()
     * @param operator The address of the operator
     * @param priceAggregator The new price aggregator address
     **/
    event SetPriceAggregator(address indexed operator, address priceAggregator);

    /**
     * @dev Emitted on setRoundInterval()
     * @param operator The address of the operator
     * @param roundInterval The round interval
     **/
    event SetRoundInterval(address indexed operator, uint256 roundInterval);

    /**
     * @dev Emitted on setTimeInterval()
     * @param operator The address of the operator
     * @param timeInterval The time interval
     **/
    event SetTimeInterval(address indexed operator, uint256 timeInterval);

    /**
     * @dev Emitted on updatePrice()
     * @param nftAddress The address of the NFT
     * @param price The price of the NFT
     * @param timestamp The timestamp when the price happened
     * @param roundId The round id
     **/
    event UpdatePrice(address indexed nftAddress, uint256 price, uint256 timestamp, uint256 roundId);

    /**
     * @notice Sets round interval that is used for calculating TWAP price
     * @param roundInterval The round interval will be set
     **/
    function setRoundInterval(uint256 roundInterval) external;

    /**
     * @notice Sets time interval that is used for calculating TWAP price
     * @param timeInterval The time interval will be set
     **/
    function setTimeInterval(uint256 timeInterval) external;

    /**
     * @notice Returns the NFT price in ETH
     * @param reserveId The id of the reserve
     * @param nftAddress The address of the NFT
     * @param tokenId The id of the NFT
     * @return The price of the NFT
     **/
    function getPrice(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @notice Updates the floor price of the NFT collection
     * @param nftAddress The address of the NFT
     * @param price The price of the NFT
     * @param timestamp The timestamp when the price happened
     **/
    function updatePrice(
        address nftAddress,
        uint256 price,
        uint256 timestamp
    ) external;
}