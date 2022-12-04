// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Curve/ICurveGauge.sol";
import "./Base/ISelfStakingERC20.sol";

interface IREWardSplitter is IUpgradeableBase
{
    error GaugeNotExcluded();
    
    function isREWardSplitter() external view returns (bool);
    function splitRewards(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges) external view returns (uint256 selfStakingERC20Amount, uint256[] memory gaugeAmounts);

    function approve(IERC20 rewardToken, address[] memory targets) external;
    function addReward(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges) external;
    function addRewardPermit(uint256 amount, ISelfStakingERC20 selfStakingERC20, ICurveGauge[] calldata gauges, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}