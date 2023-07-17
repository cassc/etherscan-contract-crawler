// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOracleStruct.sol";

interface ICvgOracle {
    function getPriceOracle(IOracleStruct.OracleParams calldata oracleParams) external view returns (uint256, bool);

    function getCvgPriceOracleUnverified() external view returns (uint256);

    function getEthPriceOracleUnverified() external view returns (uint256);

    function getAndVerifyCvgPrice() external view returns (uint256, bool);

    function getPriceAggregator(AggregatorV3Interface aggregator) external view returns (uint256, uint256);

    function getAndVerifyPrice(
        IOracleStruct.OracleParams memory oracleParams,
        bool isStable
    ) external view returns (uint256, bool);
}