// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

interface IOracle{
    function putPrice(address asset, uint64 timestamp, uint256 price) external;

    function updatePrices(NewPrice[] calldata _array) external;

    function setStalenessThresholds(address[] calldata tokens, uint32[] calldata thresholds) external;

    function STALENESS_DEFAULT_THRESHOLD() external view returns (uint32);

    function getPrice(address) external view returns (uint64, uint64, uint256, uint256);

    function getLatestPrice(address asset) external view returns (uint256 price);

    function getStalenessThreshold(address) external view returns (uint32);

    function decimals() external pure returns (uint8);

    // Struct of main contract XOracle
    struct Price{
        address asset;
        uint64 timestamp;
        uint64 prev_timestamp;
        uint256 price;
        uint256 prev_price;
    }

    struct NewPrice{
        address asset;
        uint64 timestamp;
        uint256 price;
    }
}