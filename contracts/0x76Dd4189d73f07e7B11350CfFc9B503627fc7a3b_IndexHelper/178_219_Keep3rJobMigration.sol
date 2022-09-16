// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../../interfaces/peripherals/IKeep3rJobs.sol";
import "./Keep3rJobFundableCredits.sol";
import "./Keep3rJobFundableLiquidity.sol";

abstract contract Keep3rJobMigration is IKeep3rJobMigration, Keep3rJobFundableCredits, Keep3rJobFundableLiquidity {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant _MIGRATION_COOLDOWN = 1 minutes;

    /// @inheritdoc IKeep3rJobMigration
    mapping(address => address) public override pendingJobMigrations;
    mapping(address => mapping(address => uint256)) internal _migrationCreatedAt;

    /// @inheritdoc IKeep3rJobMigration
    function migrateJob(address _fromJob, address _toJob) external override onlyJobOwner(_fromJob) {
        if (_fromJob == _toJob) revert JobMigrationImpossible();

        pendingJobMigrations[_fromJob] = _toJob;
        _migrationCreatedAt[_fromJob][_toJob] = block.timestamp;

        emit JobMigrationRequested(_fromJob, _toJob);
    }

    /// @inheritdoc IKeep3rJobMigration
    function acceptJobMigration(address _fromJob, address _toJob) external override onlyJobOwner(_toJob) {
        if (disputes[_fromJob] || disputes[_toJob]) revert JobDisputed();
        if (pendingJobMigrations[_fromJob] != _toJob) revert JobMigrationUnavailable();
        if (block.timestamp < _migrationCreatedAt[_fromJob][_toJob] + _MIGRATION_COOLDOWN) revert JobMigrationLocked();

        // force job credits update for both jobs
        _settleJobAccountance(_fromJob);
        _settleJobAccountance(_toJob);

        // migrate tokens
        while (_jobTokens[_fromJob].length() > 0) {
            address _tokenToMigrate = _jobTokens[_fromJob].at(0);
            jobTokenCredits[_toJob][_tokenToMigrate] += jobTokenCredits[_fromJob][_tokenToMigrate];
            jobTokenCredits[_fromJob][_tokenToMigrate] = 0;
            _jobTokens[_fromJob].remove(_tokenToMigrate);
            _jobTokens[_toJob].add(_tokenToMigrate);
        }

        // migrate liquidities
        while (_jobLiquidities[_fromJob].length() > 0) {
            address _liquidity = _jobLiquidities[_fromJob].at(0);

            liquidityAmount[_toJob][_liquidity] += liquidityAmount[_fromJob][_liquidity];
            delete liquidityAmount[_fromJob][_liquidity];

            _jobLiquidities[_toJob].add(_liquidity);
            _jobLiquidities[_fromJob].remove(_liquidity);
        }

        // migrate job balances
        _jobPeriodCredits[_toJob] += _jobPeriodCredits[_fromJob];
        delete _jobPeriodCredits[_fromJob];

        _jobLiquidityCredits[_toJob] += _jobLiquidityCredits[_fromJob];
        delete _jobLiquidityCredits[_fromJob];

        // stop _fromJob from being a job
        delete rewardedAt[_fromJob];
        _jobs.remove(_fromJob);

        // delete unused data slots
        delete jobOwner[_fromJob];
        delete jobPendingOwner[_fromJob];
        delete _migrationCreatedAt[_fromJob][_toJob];
        delete pendingJobMigrations[_fromJob];

        emit JobMigrationSuccessful(_fromJob, _toJob);
    }
}