// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;

interface IETHPlatform {
    function depositETH(uint256 minLPTokenAmount) external payable returns (uint256 lpTokenAmount);
    function openPositionETH(uint16 maxCVI, uint168 maxBuyingPremiumFeePercentage, uint8 leverage) external payable returns (uint256 positionUnitsAmount);
}