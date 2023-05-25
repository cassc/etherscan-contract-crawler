// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobOwnership.sol';
import '../Keep3rAccountance.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/IPairManager.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

import '../../libraries/FullMath.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

abstract contract Keep3rJobFundableLiquidity is IKeep3rJobFundableLiquidity, ReentrancyGuard, Keep3rJobOwnership, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @notice List of liquidities that are accepted in the system
  EnumerableSet.AddressSet internal _approvedLiquidities;

  /// @inheritdoc IKeep3rJobFundableLiquidity
  mapping(address => mapping(address => uint256)) public override liquidityAmount;

  /// @inheritdoc IKeep3rJobFundableLiquidity
  mapping(address => uint256) public override rewardedAt;

  /// @inheritdoc IKeep3rJobFundableLiquidity
  mapping(address => uint256) public override workedAt;

  /// @notice Tracks an address and returns its TickCache
  mapping(address => TickCache) internal _tick;

  // Views

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function approvedLiquidities() external view override returns (address[] memory _list) {
    _list = _approvedLiquidities.values();
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function jobPeriodCredits(address _job) public view override returns (uint256 _periodCredits) {
    for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
      address _liquidity = _jobLiquidities[_job].at(i);
      if (_approvedLiquidities.contains(_liquidity)) {
        TickCache memory _tickCache = observeLiquidity(_liquidity);
        if (_tickCache.period != 0) {
          int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tickCache.difference : -_tickCache.difference;
          _periodCredits += _getReward(
            IKeep3rHelper(keep3rHelper).getKP3RsAtTick(liquidityAmount[_job][_liquidity], _tickDifference, rewardPeriodTime)
          );
        }
      }
    }
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function jobLiquidityCredits(address _job) public view override returns (uint256 _liquidityCredits) {
    uint256 _periodCredits = jobPeriodCredits(_job);

    // If the job was rewarded in the past 1 period time
    if ((block.timestamp - rewardedAt[_job]) < rewardPeriodTime) {
      // If the job has period credits, update minted job credits to new twap
      _liquidityCredits = _periodCredits > 0
        ? (_jobLiquidityCredits[_job] * _periodCredits) / _jobPeriodCredits[_job] // If the job has period credits, return remaining job credits updated to new twap
        : _jobLiquidityCredits[_job]; // If not, return remaining credits, forced credits should not be updated
    } else {
      // Else return a full period worth of credits if current credits have expired
      _liquidityCredits = _periodCredits;
    }
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function totalJobCredits(address _job) external view override returns (uint256 _credits) {
    uint256 _periodCredits = jobPeriodCredits(_job);
    uint256 _cooldown = block.timestamp;

    if ((rewardedAt[_job] > _period(block.timestamp - rewardPeriodTime))) {
      // Will calculate cooldown if it outdated
      if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
        // Will calculate cooldown from last reward reference in this period
        _cooldown -= (rewardedAt[_job] + rewardPeriodTime);
      } else {
        // Will calculate cooldown from last reward timestamp
        _cooldown -= rewardedAt[_job];
      }
    } else {
      // Will calculate cooldown from period start if expired
      _cooldown -= _period(block.timestamp);
    }
    _credits = jobLiquidityCredits(_job) + _phase(_cooldown, _periodCredits);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function quoteLiquidity(address _liquidity, uint256 _amount) external view override returns (uint256 _periodCredits) {
    if (_approvedLiquidities.contains(_liquidity)) {
      TickCache memory _tickCache = observeLiquidity(_liquidity);
      if (_tickCache.period != 0) {
        int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tickCache.difference : -_tickCache.difference;
        return _getReward(IKeep3rHelper(keep3rHelper).getKP3RsAtTick(_amount, _tickDifference, rewardPeriodTime));
      }
    }
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function observeLiquidity(address _liquidity) public view override returns (TickCache memory _tickCache) {
    if (_tick[_liquidity].period == _period(block.timestamp)) {
      // Will return cached twaps if liquidity is updated
      _tickCache = _tick[_liquidity];
    } else {
      bool success;
      uint256 lastPeriod = _period(block.timestamp - rewardPeriodTime);

      if (_tick[_liquidity].period == lastPeriod) {
        // Will only ask for current period accumulator if liquidity is outdated
        uint32[] memory _secondsAgo = new uint32[](1);
        int56 previousTick = _tick[_liquidity].current;

        _secondsAgo[0] = uint32(block.timestamp - _period(block.timestamp));

        (_tickCache.current, , success) = IKeep3rHelper(keep3rHelper).observe(_liquidityPool[_liquidity], _secondsAgo);

        _tickCache.difference = _tickCache.current - previousTick;
      } else if (_tick[_liquidity].period < lastPeriod) {
        // Will ask for 2 accumulators if liquidity is expired
        uint32[] memory _secondsAgo = new uint32[](2);

        _secondsAgo[0] = uint32(block.timestamp - _period(block.timestamp));
        _secondsAgo[1] = uint32(block.timestamp - _period(block.timestamp) + rewardPeriodTime);

        int56 _tickCumulative2;
        (_tickCache.current, _tickCumulative2, success) = IKeep3rHelper(keep3rHelper).observe(_liquidityPool[_liquidity], _secondsAgo);

        _tickCache.difference = _tickCache.current - _tickCumulative2;
      }
      if (success) {
        _tickCache.period = _period(block.timestamp);
      } else {
        delete _tickCache.period;
      }
    }
  }

  // Methods

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function forceLiquidityCreditsToJob(address _job, uint256 _amount) external override onlyGovernance {
    if (!_jobs.contains(_job)) revert JobUnavailable();
    _settleJobAccountance(_job);
    _jobLiquidityCredits[_job] += _amount;
    emit LiquidityCreditsForced(_job, rewardedAt[_job], _jobLiquidityCredits[_job]);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function approveLiquidity(address _liquidity) external override onlyGovernance {
    if (!_approvedLiquidities.add(_liquidity)) revert LiquidityPairApproved();
    _liquidityPool[_liquidity] = IPairManager(_liquidity).pool();
    _isKP3RToken0[_liquidity] = IKeep3rHelper(keep3rHelper).isKP3RToken0(_liquidityPool[_liquidity]);
    _tick[_liquidity] = observeLiquidity(_liquidity);
    emit LiquidityApproval(_liquidity);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function revokeLiquidity(address _liquidity) external override onlyGovernance {
    if (!_approvedLiquidities.remove(_liquidity)) revert LiquidityPairUnexistent();
    emit LiquidityRevocation(_liquidity);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function addLiquidityToJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external override nonReentrant {
    if (!_approvedLiquidities.contains(_liquidity)) revert LiquidityPairUnapproved();
    if (!_jobs.contains(_job)) revert JobUnavailable();

    _jobLiquidities[_job].add(_liquidity);

    _settleJobAccountance(_job);

    if (_quoteLiquidity(liquidityAmount[_job][_liquidity] + _amount, _liquidity) < liquidityMinimum) revert JobLiquidityLessThanMin();

    emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);

    IERC20(_liquidity).safeTransferFrom(msg.sender, address(this), _amount);
    liquidityAmount[_job][_liquidity] += _amount;
    _jobPeriodCredits[_job] += _getReward(_quoteLiquidity(_amount, _liquidity));
    emit LiquidityAddition(_job, _liquidity, msg.sender, _amount);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external override onlyJobOwner(_job) {
    canWithdrawAfter[_job][_liquidity] = block.timestamp + unbondTime;
    pendingUnbonds[_job][_liquidity] += _amount;
    _unbondLiquidityFromJob(_job, _liquidity, _amount);

    uint256 _remainingLiquidity = liquidityAmount[_job][_liquidity];
    if (_remainingLiquidity > 0 && _quoteLiquidity(_remainingLiquidity, _liquidity) < liquidityMinimum) revert JobLiquidityLessThanMin();

    emit Unbonding(_job, _liquidity, _amount);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function withdrawLiquidityFromJob(
    address _job,
    address _liquidity,
    address _receiver
  ) external override onlyJobOwner(_job) {
    if (_receiver == address(0)) revert ZeroAddress();
    if (pendingUnbonds[_job][_liquidity] == 0) revert UnbondsUnexistent();
    if (canWithdrawAfter[_job][_liquidity] >= block.timestamp) revert UnbondsLocked();
    if (disputes[_job]) revert Disputed();

    uint256 _amount = pendingUnbonds[_job][_liquidity];

    delete pendingUnbonds[_job][_liquidity];
    delete canWithdrawAfter[_job][_liquidity];

    IERC20(_liquidity).safeTransfer(_receiver, _amount);
    emit LiquidityWithdrawal(_job, _liquidity, _receiver, _amount);
  }

  // Internal functions

  /// @notice Updates or rewards job liquidity credits depending on time since last job reward
  function _updateJobCreditsIfNeeded(address _job) internal returns (bool _rewarded) {
    if (rewardedAt[_job] < _period(block.timestamp)) {
      // Will exit function if job has been rewarded in current period
      if (rewardedAt[_job] <= _period(block.timestamp - rewardPeriodTime)) {
        // Will reset job to period syncronicity if a full period passed without rewards
        _updateJobPeriod(_job);
        _jobLiquidityCredits[_job] = _jobPeriodCredits[_job];
        rewardedAt[_job] = _period(block.timestamp);
        _rewarded = true;
      } else if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
        // Will reset job's syncronicity if last reward was more than epoch ago
        _updateJobPeriod(_job);
        _jobLiquidityCredits[_job] = _jobPeriodCredits[_job];
        rewardedAt[_job] += rewardPeriodTime;
        _rewarded = true;
      } else if (workedAt[_job] < _period(block.timestamp)) {
        // First keeper on period has to update job accountance to current twaps
        uint256 previousPeriodCredits = _jobPeriodCredits[_job];
        _updateJobPeriod(_job);
        _jobLiquidityCredits[_job] = (_jobLiquidityCredits[_job] * _jobPeriodCredits[_job]) / previousPeriodCredits;
        // Updating job accountance does not reward job
      }
    }
  }

  /// @notice Only called if _jobLiquidityCredits < payment
  function _rewardJobCredits(address _job) internal {
    /// @notice Only way to += jobLiquidityCredits is when keeper rewarding (cannot pay work)
    /* WARNING: this allows to top up _jobLiquidityCredits to a max of 1.99 but have to spend at least 1 */
    _jobLiquidityCredits[_job] += _phase(block.timestamp - rewardedAt[_job], _jobPeriodCredits[_job]);
    rewardedAt[_job] = block.timestamp;
  }

  /// @notice Updates accountance for _jobPeriodCredits
  function _updateJobPeriod(address _job) internal {
    _jobPeriodCredits[_job] = _calculateJobPeriodCredits(_job);
  }

  /// @notice Quotes the outdated job liquidities and calculates _periodCredits
  /// @dev This function is also responsible for keeping the KP3R/WETH quote updated
  function _calculateJobPeriodCredits(address _job) internal returns (uint256 _periodCredits) {
    if (_tick[kp3rWethPool].period != _period(block.timestamp)) {
      // Updates KP3R/WETH quote if needed
      _tick[kp3rWethPool] = observeLiquidity(kp3rWethPool);
    }

    for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
      address _liquidity = _jobLiquidities[_job].at(i);
      if (_approvedLiquidities.contains(_liquidity)) {
        if (_tick[_liquidity].period != _period(block.timestamp)) {
          // Updates liquidity cache only if needed
          _tick[_liquidity] = observeLiquidity(_liquidity);
        }
        _periodCredits += _getReward(_quoteLiquidity(liquidityAmount[_job][_liquidity], _liquidity));
      }
    }
  }

  /// @notice Updates job accountance calculating the impact of the unbonded liquidity amount
  function _unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) internal nonReentrant {
    if (!_jobLiquidities[_job].contains(_liquidity)) revert JobLiquidityUnexistent();
    if (liquidityAmount[_job][_liquidity] < _amount) revert JobLiquidityInsufficient();

    // Ensures current twaps in job liquidities
    _updateJobPeriod(_job);
    uint256 _periodCreditsToRemove = _getReward(_quoteLiquidity(_amount, _liquidity));

    // A liquidity can be revoked causing a job to have 0 periodCredits
    if (_jobPeriodCredits[_job] > 0) {
      // Removes a % correspondant to a full rewardPeriodTime for the liquidity withdrawn vs all of the liquidities
      _jobLiquidityCredits[_job] -= (_jobLiquidityCredits[_job] * _periodCreditsToRemove) / _jobPeriodCredits[_job];
      _jobPeriodCredits[_job] -= _periodCreditsToRemove;
    }

    liquidityAmount[_job][_liquidity] -= _amount;
    if (liquidityAmount[_job][_liquidity] == 0) {
      _jobLiquidities[_job].remove(_liquidity);
    }
  }

  /// @notice Returns a fraction of the multiplier or the whole multiplier if equal or more than a rewardPeriodTime has passed
  function _phase(uint256 _timePassed, uint256 _multiplier) internal view returns (uint256 _result) {
    if (_timePassed < rewardPeriodTime) {
      _result = (_timePassed * _multiplier) / rewardPeriodTime;
    } else _result = _multiplier;
  }

  /// @notice Returns the start of the period of the provided timestamp
  function _period(uint256 _timestamp) internal view returns (uint256 _periodTimestamp) {
    return _timestamp - (_timestamp % rewardPeriodTime);
  }

  /// @notice Calculates relation between rewardPeriod and inflationPeriod
  function _getReward(uint256 _baseAmount) internal view returns (uint256 _credits) {
    return FullMath.mulDiv(_baseAmount, rewardPeriodTime, inflationPeriod);
  }

  /// @notice Returns underlying KP3R amount for a given liquidity amount
  function _quoteLiquidity(uint256 _amount, address _liquidity) internal view returns (uint256 _quote) {
    if (_tick[_liquidity].period != 0) {
      int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tick[_liquidity].difference : -_tick[_liquidity].difference;
      _quote = IKeep3rHelper(keep3rHelper).getKP3RsAtTick(_amount, _tickDifference, rewardPeriodTime);
    }
  }

  /// @notice Updates job credits to current quotes and rewards job's pending minted credits
  /// @dev Ensures a maximum of 1 period of credits
  function _settleJobAccountance(address _job) internal virtual {
    _updateJobCreditsIfNeeded(_job);
    _rewardJobCredits(_job);
    _jobLiquidityCredits[_job] = Math.min(_jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
  }
}