// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IConicPool.sol";
import "IController.sol";
import "IRebalancingRewardsHandler.sol";

interface ICNCMintingRebalancingRewardsHandler is IRebalancingRewardsHandler {
    event SetCncRebalancingRewardPerDollarPerSecond(uint256 cncRebalancingRewardPerDollarPerSecond);
    event SetMaxRebalancingRewardDollarMultiplier(uint256 maxRebalancingRewardDollarMultiplier);
    event SetMinRebalancingRewardDollarMultiplier(uint256 minRebalancingRewardDollarMultiplier);

    function controller() external view returns (IController);

    function totalCncMinted() external view returns (uint256);

    function cncRebalancingRewardPerDollarPerSecond() external view returns (uint256);

    function maxRebalancingRewardDollarMultiplier() external view returns (uint256);

    function minRebalancingRewardDollarMultiplier() external view returns (uint256);

    function setCncRebalancingRewardPerDollarPerSecond(
        uint256 _cncRebalancingRewardPerDollarPerSecond
    ) external;

    function setMaxRebalancingRewardDollarMultiplier(uint256 _maxRebalancingRewardDollarMultiplier)
        external;

    function setMinRebalancingRewardDollarMultiplier(uint256 _minRebalancingRewardDollarMultiplier)
        external;

    function poolCNCRebalancingRewardPerSecond(address pool) external view returns (uint256);

    function computeRebalancingRewards(
        address conicPool,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external view returns (uint256);
}