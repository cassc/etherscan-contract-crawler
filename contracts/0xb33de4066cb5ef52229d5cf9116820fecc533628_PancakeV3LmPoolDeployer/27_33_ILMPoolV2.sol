// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface ILMPoolV2 {
    function lmTicks(int24) external view returns (uint128, int128, uint256);

    function rewardGrowthGlobalX128() external view returns (uint256);

    function lmLiquidity() external view returns (uint128);

    function lastRewardTimestamp() external view returns (uint32);

    function getRewardGrowthInside(int24 tickLower, int24 tickUpper) external view returns (uint256);

    function firstLMPool() external view returns (address);

    function secondLMPool() external view returns (address);

    function lmTicksFlag(int24 tick) external view returns (bool);

    function negativeRewardGrowthInsideFlag(int24 tickLower, int24 tickUpper) external view returns (bool);

    function negativeRewardGrowthInsideInitValue(int24 tickLower, int24 tickUpper) external view returns (uint256);

    function checkNegativeFlag(int24 tickLower, int24 tickUpper) external view returns (bool);
}