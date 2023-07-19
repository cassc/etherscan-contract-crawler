// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "../pools/ITorusPool.sol";
import "../IController.sol";
import "./IRebalancingRewardsHandler.sol";

interface ITORUSMintingRebalancingRewardsHandler is IRebalancingRewardsHandler {
    event SetTorusRebalancingRewardPerDollarPerSecond(uint256 torusRebalancingRewardPerDollarPerSecond);
    event SetMaxRebalancingRewardDollarMultiplier(uint256 maxRebalancingRewardDollarMultiplier);
    event SetMinRebalancingRewardDollarMultiplier(uint256 minRebalancingRewardDollarMultiplier);

    function controller() external view returns (IController);

    function totalTorusMinted() external view returns (uint256);

    function torusRebalancingRewardPerDollarPerSecond() external view returns (uint256);

    function maxRebalancingRewardDollarMultiplier() external view returns (uint256);

    function minRebalancingRewardDollarMultiplier() external view returns (uint256);

    function setTorusRebalancingRewardPerDollarPerSecond(
        uint256 _torusRebalancingRewardPerDollarPerSecond
    ) external;

    function setMaxRebalancingRewardDollarMultiplier(uint256 _maxRebalancingRewardDollarMultiplier)
        external;

    function setMinRebalancingRewardDollarMultiplier(uint256 _minRebalancingRewardDollarMultiplier)
        external;

    function poolTORUSRebalancingRewardPerSecond(address pool) external view returns (uint256);

    function computeRebalancingRewards(
        address torusPool,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external view returns (uint256);
}