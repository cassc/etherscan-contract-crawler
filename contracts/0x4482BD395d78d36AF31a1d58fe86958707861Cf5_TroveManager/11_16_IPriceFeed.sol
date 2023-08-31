// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    event NewOracleRegistered(address token, address chainlinkAggregator, bool isEthIndexed);
    event PriceFeedStatusUpdated(address token, address oracle, bool isWorking);
    event PriceRecordUpdated(address indexed token, uint256 _price);

    function fetchPrice(address _token) external returns (uint256);

    function setOracle(
        address _token,
        address _chainlinkOracle,
        bytes4 sharePriceSignature,
        uint8 sharePriceDecimals,
        bool _isEthIndexed
    ) external;

    function MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND() external view returns (uint256);

    function PRISMA_CORE() external view returns (address);

    function RESPONSE_TIMEOUT() external view returns (uint256);

    function TARGET_DIGITS() external view returns (uint256);

    function guardian() external view returns (address);

    function oracleRecords(
        address
    )
        external
        view
        returns (
            address chainLinkOracle,
            uint8 decimals,
            bytes4 sharePriceSignature,
            uint8 sharePriceDecimals,
            bool isFeedWorking,
            bool isEthIndexed
        );

    function owner() external view returns (address);

    function priceRecords(
        address
    ) external view returns (uint96 scaledPrice, uint32 timestamp, uint32 lastUpdated, uint80 roundId);
}