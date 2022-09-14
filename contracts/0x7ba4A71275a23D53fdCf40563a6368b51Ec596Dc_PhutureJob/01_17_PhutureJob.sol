// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/IKeeper3r.sol";
import "./external/interfaces/IKeep3r.sol";
import "./interfaces/IHarvestingJob.sol";
import "./interfaces/ISavingsVaultHarvester.sol";
import "./interfaces/IJobConfig.sol";
import "./interfaces/IPhutureJob.sol";

/// @title Phuture job
/// @notice Contains harvesting execution logic through keeper network
contract PhutureJob is IPhutureJob, IKeeper3r, IHarvestingJob, Pausable, Ownable {
    /// @inheritdoc IKeeper3r
    address public immutable override keep3r;

    /// @inheritdoc IPhutureJob
    address public override jobConfig;

    /// @inheritdoc IHarvestingJob
    mapping(address => uint96) public lastHarvest;

//    /// @notice Pays keeper for work
//    modifier payKeeper(address _keeper) {
//        require(IKeep3r(keep3r).isKeeper(_keeper), "PhutureJob: !KEEP3R");
//        _;
//        IKeep3r(keep3r).worked(_keeper);
//    }

    constructor(address _keep3r, address _jobConfig) {
        keep3r = _keep3r;
        jobConfig = _jobConfig;
//        _pause();
    }

    /// @inheritdoc IHarvestingJob
    function pause() external override onlyOwner {
        _pause();
    }

    /// @inheritdoc IHarvestingJob
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @inheritdoc IPhutureJob
    function setJobConfig(address _jobConfig) external onlyOwner {
        jobConfig = _jobConfig;
    }

    /// @inheritdoc IHarvestingJob
    function harvest(ISavingsVaultHarvester _vault) external override {
        require(canHarvest(_vault), "PhutureJob:TIMEOUT");
        uint depositedAmount = IJobConfig(jobConfig).getDepositedAmount(address(_vault));
        require(depositedAmount != 0, "PhutureJob:NOTHING_TO_DEPOSIT");
        _vault.harvest(depositedAmount);
        lastHarvest[address(_vault)] = uint96(block.timestamp);
    }

    /// @inheritdoc IHarvestingJob
    function canHarvest(ISavingsVaultHarvester _vault) public view returns (bool) {
        return block.timestamp - lastHarvest[address(_vault)] >= _vault.timeout();
    }
}