// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IJPEGOraclesAggregator {
    function getFloorETH() external view returns (uint256);
    function consultJPEGPriceETH(address _token) external returns (uint256 result);
}