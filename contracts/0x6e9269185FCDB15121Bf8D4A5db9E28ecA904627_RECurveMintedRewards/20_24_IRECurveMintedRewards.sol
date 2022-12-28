// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Curve/ICurveGauge.sol";
import "./Base/ICanMint.sol";

interface IRECurveMintedRewards is IUpgradeableBase
{
    event RewardRate(uint256 perDay, uint256 perDayPerUnit);

    error NotRewardManager();

    function isRECurveMintedRewards() external view returns (bool);
    function gauge() external view returns (ICurveGauge);
    function lastRewardTimestamp() external view returns (uint256);
    function rewardToken() external view returns (ICanMint);
    function perDay() external view returns (uint256);
    function perDayPerUnit() external view returns (uint256);
    function isRewardManager(address user) external view returns (bool);
    
    function sendRewards(uint256 units) external;
    function sendAndSetRewardRate(uint256 perDay, uint256 perDayPerUnit, uint256 units) external;
    function setRewardManager(address manager, bool enabled) external;
}