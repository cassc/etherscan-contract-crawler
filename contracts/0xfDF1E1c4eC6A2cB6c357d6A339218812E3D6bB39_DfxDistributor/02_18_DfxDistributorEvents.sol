// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "IERC20.sol";
import "SafeERC20.sol";
import "AccessControlUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";

import "IGaugeController.sol";
import "ILiquidityGauge.sol";
import "IDfxMiddlemanGauge.sol";
import "IStakingRewards.sol";

// import "AccessControlUpgradeable.sol";

/// @title DfxDistributorEvents
/// @author Forked from contracts developed by Angle and adapted by DFX
/// - AngleDistributorEvents.sol (https://github.com/AngleProtocol/angle-core/blob/main/contracts/staking/AngleDistributorEvents.sol)
/// @notice All the events used in `DfxDistributor` contract
contract DfxDistributorEvents {
    event DelegateGaugeUpdated(address indexed _gaugeAddr, address indexed _delegateGauge);
    event DistributionsToggled(bool _distributionsOn);
    event GaugeControllerUpdated(address indexed _controller);
    event GaugeToggled(address indexed gaugeAddr, bool newStatus);
    event InterfaceKnownToggled(address indexed _delegateGauge, bool _isInterfaceKnown);
    event RateUpdated(uint256 _newRate);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);
    event RewardDistributed(address indexed gaugeAddr, uint256 rewardTally);
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
}