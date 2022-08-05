pragma solidity ^0.5.16;

interface V1PriceOracleInterface {
    function assetPrices(address asset) external view returns (uint256);
}