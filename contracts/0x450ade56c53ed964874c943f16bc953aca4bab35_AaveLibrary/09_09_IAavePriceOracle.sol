pragma solidity >=0.8.0;

interface IAavePriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}