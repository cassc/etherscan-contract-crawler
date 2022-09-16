// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJobMigration.sol";
import "../../../interfaces/IKeep3rHelper.sol";
import "../../../interfaces/peripherals/IKeep3rJobs.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Keep3rJobWorkable is IKeep3rJobWorkable, Keep3rJobMigration {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 internal _initialGas;

    /// @inheritdoc IKeep3rJobWorkable
    function isKeeper(address _keeper) external override returns (bool _isKeeper) {
        _initialGas = gasleft();
        if (_keepers.contains(_keeper)) {
            emit KeeperValidation(gasleft());
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
        _initialGas = gasleft();
        if (
            _keepers.contains(_keeper) &&
            bonds[_keeper][_bond] >= _minBond &&
            workCompleted[_keeper] >= _earned &&
            block.timestamp - firstSeen[_keeper] >= _age
        ) {
            emit KeeperValidation(gasleft());
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

        uint256 _gasRecord = gasleft();
        uint256 _boost = IKeep3rHelper(keep3rHelper).getRewardBoostFor(bonds[_keeper][keep3rV1]);

        uint256 _payment = (_quoteLiquidity(_initialGas - _gasRecord, kp3rWethPool) * _boost) / BASE;

        if (_payment > _jobLiquidityCredits[_job]) {
            _rewardJobCredits(_job);
            emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
        }

        uint256 _gasUsed = _initialGas - gasleft();
        _payment = (_gasUsed * _payment) / (_initialGas - _gasRecord);

        _bondedPayment(_job, _keeper, _payment);
        emit KeeperWork(keep3rV1, _job, _keeper, _payment, gasleft());
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
        emit KeeperWork(keep3rV1, _job, _keeper, _payment, gasleft());
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
        emit KeeperWork(_token, _job, _keeper, _amount, gasleft());
    }
}