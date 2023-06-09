// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "../Pricing/IPricing.sol";

interface IOracle {

    event SnapshotCreate(
        uint256 indexed index,
        IPricing.Prices prices,
        IPricing.AssetDetails assets,
        uint256 cumulativePrice,
        address indexed sender
    );

    struct OracleData {
        address primaryAsset;
        uint16 currentIndex;
        uint16 maxLength;
        uint32 lastBlock;
    }

    struct Operation {
        uint128 plus;
        uint128 minus;
    }

    struct Snapshot {
        IPricing.Prices prices;
        uint256 cumulativePrice;
    }

    function data() external view returns (OracleData memory);
    function latestSnapshot() external view returns (Snapshot memory);
    function snapshotAt(uint256 index) external view returns (Snapshot memory);
    function snapshotAtTimestamp(uint256 timestamp) external view returns (Snapshot memory);

    function primaryAsset() external view returns (address);
    function prices() external view returns (IPricing.Prices memory);
    function pricesAtTimestamp(uint256 timestamp) external view returns (IPricing.Prices memory);
    function cumulativePriceLAST() external view returns (uint256);

    function avgPriceFrom(uint256 timestamp) external view returns (uint256);

    function createSnapshot() external returns (IPricing.Prices memory prices);
}