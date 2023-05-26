// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@lbertenasco/contract-utils/contracts/abstract/UtilsReady.sol';
import '@lbertenasco/contract-utils/contracts/keep3r/Keep3rAbstract.sol';

import '../keep3r-liquidity-manager/Keep3rLiquidityManagerWork.sol';
import './IKeep3rLiquidityManagerJob.sol';

contract Keep3rLiquidityManagerJob is UtilsReady, Keep3r, IKeep3rLiquidityManagerJob {
  using SafeMath for uint256;

  uint256 public constant PRECISION = 1_000;
  uint256 public constant MAX_REWARD_MULTIPLIER = 1 * PRECISION; // 1x max reward multiplier
  uint256 public override rewardMultiplier = MAX_REWARD_MULTIPLIER;

  address public override keep3rLiquidityManager;

  constructor(
    address _keep3rLiquidityManager,
    address _keep3r,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) public UtilsReady() Keep3r(_keep3r) {
    _setKeep3rRequirements(_bond, _minBond, _earned, _age, _onlyEOA);
    _setKeep3rLiquidityManager(_keep3rLiquidityManager);
  }

  // Keep3r Setters
  function setKeep3r(address _keep3r) external override onlyGovernor {
    _setKeep3r(_keep3r);
  }

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) external override onlyGovernor {
    _setKeep3rRequirements(_bond, _minBond, _earned, _age, _onlyEOA);
  }

  function setRewardMultiplier(uint256 _rewardMultiplier) external override onlyGovernor {
    _setRewardMultiplier(_rewardMultiplier);
    emit SetRewardMultiplier(_rewardMultiplier);
  }

  function _setRewardMultiplier(uint256 _rewardMultiplier) internal {
    require(_rewardMultiplier <= MAX_REWARD_MULTIPLIER, 'Keep3rLiquidityManagerJob::set-reward-multiplier:multiplier-exceeds-max');
    rewardMultiplier = _rewardMultiplier;
  }

  function setKeep3rLiquidityManager(address _keep3rLiquidityManager) external override onlyGovernor {
    _setKeep3rLiquidityManager(_keep3rLiquidityManager);
    emit SetKeep3rLiquidityManager(_keep3rLiquidityManager);
  }

  function _setKeep3rLiquidityManager(address _keep3rLiquidityManager) internal {
    require(_keep3rLiquidityManager != address(0), 'Keep3rLiquidityManagerJob::set-keep3r-liqudiity-manager:not-address-0');
    keep3rLiquidityManager = _keep3rLiquidityManager;
  }

  // Setters
  function workable(address _job) external override notPaused returns (bool) {
    return _workable(_job);
  }

  function _workable(address _job) internal view returns (bool) {
    return IKeep3rLiquidityManagerWork(keep3rLiquidityManager).workable(_job);
  }

  //Getters
  function jobs() public view override returns (address[] memory _jobs) {
    return IKeep3rLiquidityManagerJobsLiquidityHandler(keep3rLiquidityManager).jobs();
  }

  // Keeper actions
  function _work(address _job, bool _workForTokens) internal returns (uint256 _credits) {
    uint256 _initialGas = gasleft();

    require(_workable(_job), 'Keep3rLiquidityManagerJob::work:not-workable');

    _keep3rLiquidityManagerWork(_job);

    _credits = _calculateCredits(_initialGas);

    emit Worked(_job, msg.sender, _credits, _workForTokens);
  }

  function work(address _job) external override returns (uint256 _credits) {
    return workForBond(_job);
  }

  function workForBond(address _job) public override notPaused onlyKeeper returns (uint256 _credits) {
    _credits = _work(_job, false);
    _paysKeeperAmount(msg.sender, _credits);
  }

  function workForTokens(address _job) external override notPaused onlyKeeper returns (uint256 _credits) {
    _credits = _work(_job, true);
    _paysKeeperInTokens(msg.sender, _credits);
  }

  function _calculateCredits(uint256 _initialGas) internal view returns (uint256 _credits) {
    // Gets default credits from KP3R_Helper and applies job reward multiplier
    return _getQuoteLimit(_initialGas).mul(rewardMultiplier).div(PRECISION);
  }

  // Mechanics keeper bypass
  function forceWork(address _job) external override onlyGovernor {
    _keep3rLiquidityManagerWork(_job);
    emit ForceWorked(_job);
  }

  function _keep3rLiquidityManagerWork(address _job) internal {
    IKeep3rLiquidityManagerWork(keep3rLiquidityManager).work(_job);
  }
}