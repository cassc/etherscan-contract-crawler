// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v1;

interface IClaimZap {
    function claimRewards(
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens,
        uint256 depositCrvMaxAmount,
        uint256 minAmountOut,
        uint256 depositCvxMaxAmount,
        uint256 spendCvxAmount,
        uint256 options
    ) external;

    function crv() external view returns (address);

    function cvx() external view returns (address);
}