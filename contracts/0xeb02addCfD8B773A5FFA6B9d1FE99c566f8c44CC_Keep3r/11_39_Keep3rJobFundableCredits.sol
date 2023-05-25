// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobOwnership.sol';
import '../Keep3rAccountance.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

abstract contract Keep3rJobFundableCredits is IKeep3rJobFundableCredits, ReentrancyGuard, Keep3rJobOwnership, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @notice Cooldown between withdrawals
  uint256 internal constant _WITHDRAW_TOKENS_COOLDOWN = 1 minutes;

  /// @inheritdoc IKeep3rJobFundableCredits
  mapping(address => mapping(address => uint256)) public override jobTokenCreditsAddedAt;

  /// @inheritdoc IKeep3rJobFundableCredits
  function addTokenCreditsToJob(
    address _job,
    address _token,
    uint256 _amount
  ) external override nonReentrant {
    if (!_jobs.contains(_job)) revert JobUnavailable();
    // KP3R shouldn't be used for direct token payments
    if (_token == keep3rV1) revert TokenUnallowed();
    uint256 _before = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _received = IERC20(_token).balanceOf(address(this)) - _before;
    uint256 _tokenFee = (_received * fee) / _BASE;
    jobTokenCredits[_job][_token] += _received - _tokenFee;
    jobTokenCreditsAddedAt[_job][_token] = block.timestamp;
    IERC20(_token).safeTransfer(governance, _tokenFee);
    _jobTokens[_job].add(_token);

    emit TokenCreditAddition(_job, _token, msg.sender, _received);
  }

  /// @inheritdoc IKeep3rJobFundableCredits
  function withdrawTokenCreditsFromJob(
    address _job,
    address _token,
    uint256 _amount,
    address _receiver
  ) external override nonReentrant onlyJobOwner(_job) {
    if (block.timestamp <= jobTokenCreditsAddedAt[_job][_token] + _WITHDRAW_TOKENS_COOLDOWN) revert JobTokenCreditsLocked();
    if (jobTokenCredits[_job][_token] < _amount) revert InsufficientJobTokenCredits();
    if (disputes[_job]) revert JobDisputed();

    jobTokenCredits[_job][_token] -= _amount;
    IERC20(_token).safeTransfer(_receiver, _amount);

    if (jobTokenCredits[_job][_token] == 0) {
      _jobTokens[_job].remove(_token);
    }

    emit TokenCreditWithdrawal(_job, _token, _receiver, _amount);
  }
}