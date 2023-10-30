// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStablePool {
    function getSwapFeePercentage() external view returns (uint256);
    function getAmplificationParameter() external view returns (uint256, bool, uint256);
    function getLastInvariant() external view returns (uint256, uint256);
    function getScalingFactors() external view returns (uint256[] memory);
    function getActualSupply() external view returns (uint256);
    function getBptIndex() external view returns (uint256);
}