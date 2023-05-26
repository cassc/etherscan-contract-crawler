// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IConicPool.sol";
import "IController.sol";
import "IRebalancingRewardsHandler.sol";

interface ICNCMintingRebalancingRewardsHandlerV2 is IRebalancingRewardsHandler {
    event SetCncRebalancingRewardPerDollarPerSecond(uint256 cncRebalancingRewardPerDollarPerSecond);

    function initialize() external;

    function controller() external view returns (IController);

    function totalCncMinted() external view returns (uint256);

    function cncRebalancingRewardPerDollarPerSecond() external view returns (uint256);

    function setCncRebalancingRewardPerDollarPerSecond(
        uint256 _cncRebalancingRewardPerDollarPerSecond
    ) external;

    function computeRebalancingRewards(
        address conicPool,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external view returns (uint256);

    function rebalance(
        address conicPool,
        uint256 underlyingAmount,
        uint256 minUnderlyingReceived,
        uint256 minCNCReceived
    ) external returns (uint256 underlyingReceived, uint256 cncReceived);

    function switchMintingRebalancingRewardsHandler(address newRebalancingRewardsHandler) external;
}