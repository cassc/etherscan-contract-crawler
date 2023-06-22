pragma solidity ^0.8.10;

interface IWeightedPool {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getSwapFeePercentage() external view returns (uint256);
}