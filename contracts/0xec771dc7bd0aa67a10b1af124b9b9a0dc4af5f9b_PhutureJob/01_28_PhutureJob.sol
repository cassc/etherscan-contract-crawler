// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC4626Upgradeable.sol";

import "./interfaces/IKeeper3r.sol";
import "./external/interfaces/IKeep3r.sol";
import "./interfaces/IHarvestingJob.sol";
import "./interfaces/ISavingsVaultHarvester.sol";
import "./interfaces/IJobConfig.sol";
import "./interfaces/IPhutureJob.sol";

/// @title Phuture job
/// @notice Contains harvesting execution logic through keeper network
contract PhutureJob is IPhutureJob, IKeeper3r, IHarvestingJob, Pausable, AccessControl {
    /// @notice Responsible for all job related permissions
    bytes32 internal constant JOB_ADMIN_ROLE = keccak256("JOB_ADMIN_ROLE");
    /// @notice Role for job management
    bytes32 internal constant JOB_MANAGER_ROLE = keccak256("JOB_MANAGER_ROLE");
    /// @inheritdoc IKeeper3r
    address public immutable override keep3r;

    /// @inheritdoc IPhutureJob
    address public override jobConfig;

    /// @inheritdoc IHarvestingJob
    mapping(address => uint96) public lastHarvest;

    /// @inheritdoc IHarvestingJob
    mapping(address => uint32) public timeout;

    /// @notice Pays keeper for work
    modifier payKeeper(address _keeper) {
        require(IKeep3r(keep3r).isKeeper(_keeper), "PhutureJob: !KEEP3R");
        _;
        IKeep3r(keep3r).worked(_keeper);
    }

    constructor(address _keep3r, address _jobConfig) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(JOB_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(JOB_MANAGER_ROLE, JOB_ADMIN_ROLE);
        keep3r = _keep3r;
        jobConfig = _jobConfig;
        _pause();
    }

    /// @inheritdoc IHarvestingJob
    function pause() external override onlyRole(JOB_MANAGER_ROLE) {
        _pause();
    }

    /// @inheritdoc IHarvestingJob
    function unpause() external override onlyRole(JOB_MANAGER_ROLE) {
        _unpause();
    }

    /// @inheritdoc IPhutureJob
    function setJobConfig(address _jobConfig) external onlyRole(JOB_MANAGER_ROLE) {
        jobConfig = _jobConfig;
    }

    /// @inheritdoc IHarvestingJob
    function setTimeout(uint32 _timeout, address _savingsVault) external onlyRole(JOB_MANAGER_ROLE) {
        timeout[_savingsVault] = _timeout;
    }

    /// @inheritdoc IHarvestingJob
    function harvest(address _vault) external override whenNotPaused payKeeper(msg.sender) {
        require(!isAccountSettlementRequired(_vault), "PhutureJob: ACCOUNT_SETTLEMENT_REQUIRED");
        _harvest(_vault);
    }

    /// @inheritdoc IHarvestingJob
    function harvestWithPermission(address _vault) external override onlyRole(JOB_MANAGER_ROLE) {
        _harvest(_vault);
    }

    /// @inheritdoc IHarvestingJob
    function settleAccount(address _vault) external override whenNotPaused payKeeper(msg.sender) {
        require(isAccountSettlementRequired(_vault), "PhutureJob: ACCOUNT_SETTLEMENT_NOT_REQUIRED");
        ISavingsVault(_vault).settleAccount();
    }

    /// @inheritdoc IHarvestingJob
    function canHarvest(address _vault) public view returns (bool) {
        return block.timestamp - lastHarvest[_vault] >= timeout[_vault];
    }

    /// @inheritdoc IHarvestingJob
    function isAccountSettlementRequired(address _vault) public view returns (bool) {
        try IERC4626Upgradeable(_vault).totalAssets() returns (uint) {
            return false;
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("Must Settle"))) {
                return true;
            }
        }
        return false;
    }

    /// @notice Implements harvesting logic
    function _harvest(address _vault) internal {
        require(canHarvest(_vault), "PhutureJob: TIMEOUT");
        uint depositedAmount = IJobConfig(jobConfig).getDepositedAmount(address(_vault));
        require(depositedAmount != 0, "PhutureJob: ZERO");
        ISavingsVaultHarvester(_vault).harvest(depositedAmount);
        lastHarvest[_vault] = uint96(block.timestamp);
    }
}