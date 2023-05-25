// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobMigration.sol';
import '../../../interfaces/IKeep3rHelper.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract Keep3rJobWorkable is IKeep3rJobWorkable, Keep3rJobMigration {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  uint256 internal _initialGas;

  /// @inheritdoc IKeep3rJobWorkable
  function isKeeper(address _keeper) external override returns (bool _isKeeper) {
    _initialGas = _getGasLeft();
    if (_keepers.contains(_keeper)) {
      emit KeeperValidation(_initialGas);
      return true;
    }
  }

  /// @inheritdoc IKeep3rJobWorkable
  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) public override returns (bool _isBondedKeeper) {
    _initialGas = _getGasLeft();
    if (
      _keepers.contains(_keeper) &&
      bonds[_keeper][_bond] >= _minBond &&
      workCompleted[_keeper] >= _earned &&
      block.timestamp - firstSeen[_keeper] >= _age
    ) {
      emit KeeperValidation(_initialGas);
      return true;
    }
  }

  /// @inheritdoc IKeep3rJobWorkable
  function worked(address _keeper) external override {
    address _job = msg.sender;
    if (disputes[_job]) revert JobDisputed();
    if (!_jobs.contains(_job)) revert JobUnapproved();

    if (_updateJobCreditsIfNeeded(_job)) {
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }

    (uint256 _boost, uint256 _oneEthQuote, uint256 _extraGas) = IKeep3rHelper(keep3rHelper).getPaymentParams(bonds[_keeper][keep3rV1]);

    uint256 _gasLeft = _getGasLeft();
    uint256 _payment = _calculatePayment(_gasLeft, _extraGas, _oneEthQuote, _boost);

    if (_payment > _jobLiquidityCredits[_job]) {
      _rewardJobCredits(_job);
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);

      _gasLeft = _getGasLeft();
      _payment = _calculatePayment(_gasLeft, _extraGas, _oneEthQuote, _boost);
    }

    _bondedPayment(_job, _keeper, _payment);
    emit KeeperWork(keep3rV1, _job, _keeper, _payment, _gasLeft);
  }

  /// @inheritdoc IKeep3rJobWorkable
  function bondedPayment(address _keeper, uint256 _payment) public override {
    address _job = msg.sender;

    if (disputes[_job]) revert JobDisputed();
    if (!_jobs.contains(_job)) revert JobUnapproved();

    if (_updateJobCreditsIfNeeded(_job)) {
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }

    if (_payment > _jobLiquidityCredits[_job]) {
      _rewardJobCredits(_job);
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }

    _bondedPayment(_job, _keeper, _payment);
    emit KeeperWork(keep3rV1, _job, _keeper, _payment, _getGasLeft());
  }

  /// @inheritdoc IKeep3rJobWorkable
  function directTokenPayment(
    address _token,
    address _keeper,
    uint256 _amount
  ) external override {
    address _job = msg.sender;

    if (disputes[_job]) revert JobDisputed();
    if (disputes[_keeper]) revert Disputed();
    if (!_jobs.contains(_job)) revert JobUnapproved();
    if (jobTokenCredits[_job][_token] < _amount) revert InsufficientFunds();
    jobTokenCredits[_job][_token] -= _amount;
    IERC20(_token).safeTransfer(_keeper, _amount);
    emit KeeperWork(_token, _job, _keeper, _amount, _getGasLeft());
  }

  function _bondedPayment(
    address _job,
    address _keeper,
    uint256 _payment
  ) internal {
    if (_payment > _jobLiquidityCredits[_job]) revert InsufficientFunds();

    workedAt[_job] = block.timestamp;
    _jobLiquidityCredits[_job] -= _payment;
    bonds[_keeper][keep3rV1] += _payment;
    workCompleted[_keeper] += _payment;
  }

  /// @notice Calculate amount to be payed in KP3R, taking into account multiple parameters
  /// @param _gasLeft Amount of gas left after working the job
  /// @param _extraGas Amount of expected unaccounted gas
  /// @param _oneEthQuote Amount of KP3R equivalent to 1 ETH
  /// @param _boost Reward given to the keeper for having bonded KP3R tokens
  /// @return _payment Amount to be payed in KP3R tokens
  function _calculatePayment(
    uint256 _gasLeft,
    uint256 _extraGas,
    uint256 _oneEthQuote,
    uint256 _boost
  ) internal view returns (uint256 _payment) {
    uint256 _accountedGas = _initialGas - _gasLeft + _extraGas;
    _payment = (((_accountedGas * _boost) / _BASE) * _oneEthQuote) / 1 ether;
  }

  /// @notice Return the gas left and add 1/64 in order to match real gas left at first level of depth (EIP-150)
  /// @return _gasLeft Amount of gas left recording taking into account EIP-150
  function _getGasLeft() internal view returns (uint256 _gasLeft) {
    _gasLeft = (gasleft() * 64) / 63;
  }
}