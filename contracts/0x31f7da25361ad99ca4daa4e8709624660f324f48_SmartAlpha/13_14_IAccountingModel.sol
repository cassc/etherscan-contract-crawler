// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface IAccountingModel {
    function calcJuniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 upsideExposureRate,
        uint256 totalSeniors,
        uint256 totalBalance
    ) external pure returns (uint256);

    function calcSeniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 downsideProtectionRate,
        uint256 totalSeniors,
        uint256 totalBalance
    ) external pure returns (uint256);
}