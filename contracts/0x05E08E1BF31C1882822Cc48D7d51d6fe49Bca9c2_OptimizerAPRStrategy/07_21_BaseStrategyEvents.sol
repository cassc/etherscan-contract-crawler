// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../external/AccessControlAngle.sol";
import "../external/AccessControlAngleUpgradeable.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IPoolManager.sol";

import "../utils/Errors.sol";

/// @title BaseStrategyEvents
/// @author Angle Core Team
/// @notice Events used in the abstract `BaseStrategy` contract
contract BaseStrategyEvents {
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedMinReportDelayed(uint256 delay);

    event UpdatedMaxReportDelayed(uint256 delay);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event UpdatedRewards(address rewards);

    event UpdatedIsRewardActivated(bool activated);

    event UpdatedRewardAmountAndMinimumAmountMoved(uint256 _rewardAmount, uint256 _minimumAmountMoved);

    event EmergencyExitActivated();
}