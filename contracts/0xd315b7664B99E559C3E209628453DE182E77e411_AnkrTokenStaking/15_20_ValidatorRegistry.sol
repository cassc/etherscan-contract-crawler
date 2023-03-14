// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IStaking.sol";
import "../libs/ValidatorUtil.sol";
import "../libs/SnapshotUtil.sol";
import "./BaseStaking.sol";
import "../interfaces/IValidatorStorage.sol";

abstract contract ValidatorRegistry is BaseStaking {

    using SnapshotUtil for ValidatorSnapshot;

    event ValidatorStorageChanged(address prevValue, address newValue);

    IValidatorStorage internal _validatorStorage;

    // reserve some gap for the future upgrades
    uint256[25 - 1] private __reserved;


    function getValidatorStorage() external view returns (IValidatorStorage) {
        return _validatorStorage;
    }

    function getTotalDelegated(address validatorAddress) public view returns (uint256) {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        return uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION;
    }

    /*
     * used by frontend
     */
    function getValidatorStatus(address validatorAddress) public view override returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    ) {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        ownerAddress = validator.ownerAddress;
        status = uint8(validator.status);
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION;
        changedAt = validator.changedAt;
        totalRewards = snapshot.totalRewards;
    }

    /*
     * used by frontend
     */
    function getValidatorStatusAtEpoch(address validatorAddress, uint64 epoch) public view override returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    ) {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        ValidatorSnapshot memory snapshot = _touchValidatorSnapshotImmutable(validator, epoch);
        ownerAddress = validator.ownerAddress;
        status = uint8(validator.status);
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION;
        changedAt = validator.changedAt;
        totalRewards = snapshot.totalRewards;
        return (ownerAddress, status, totalDelegated,0,changedAt, 0, 0, 0, totalRewards);
    }

    function _touchValidatorSnapshot(Validator memory validator, uint64 epoch) internal returns (ValidatorSnapshot storage) {
        ValidatorSnapshot storage snapshot = _validatorSnapshots[validator.validatorAddress][epoch];
        // if snapshot is already initialized then just return it
        if (snapshot.totalDelegated > 0) {
            return snapshot;
        }
        // find previous snapshot to copy parameters from it
        ValidatorSnapshot memory lastModifiedSnapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        // last modified snapshot might store zero value, for first delegation it might happen and its not critical
        snapshot.totalDelegated = lastModifiedSnapshot.totalDelegated;
        snapshot.commissionRate = lastModifiedSnapshot.commissionRate;
        // we must save last affected epoch for this validator to be able to restore total delegated
        // amount in the future (check condition upper)
        if (epoch > validator.changedAt) {
            _validatorStorage.change(validator.validatorAddress, epoch);
        }
        return snapshot;
    }

    function _touchValidatorSnapshotImmutable(Validator memory validator, uint64 epoch) internal view returns (ValidatorSnapshot memory) {
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][epoch];
        // if snapshot is already initialized then just return it
        if (snapshot.totalDelegated > 0) {
            return snapshot;
        }
        // find previous snapshot to copy parameters from it
        ValidatorSnapshot memory lastModifiedSnapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        // last modified snapshot might store zero value, for first delegation it might happen and its not critical
        snapshot.totalDelegated = lastModifiedSnapshot.totalDelegated;
        snapshot.commissionRate = lastModifiedSnapshot.commissionRate;
        // return existing or new snapshot
        return snapshot;
    }

    function addValidator(address account) external onlyFromGovernance virtual override {
        _addValidator(account, account, ValidatorStatus.Active, 0, nextEpoch());
    }

    function _delegateUnsafe(address validator, address delegator, uint256 amount, uint64 sinceEpoch) internal virtual;

    function _addValidator(address validatorAddress, address validatorOwner, ValidatorStatus status, uint16 commissionRate, uint64 sinceEpoch) internal {
        // validator commission rate
        require(commissionRate >= COMMISSION_RATE_MIN_VALUE && commissionRate <= COMMISSION_RATE_MAX_VALUE, "bad commission");
        // init validator default params
        _validatorStorage.create(validatorAddress, validatorOwner, status, sinceEpoch);
        // push initial validator snapshot at zero epoch with default params
        _validatorSnapshots[validatorAddress][sinceEpoch].create(0, commissionRate);
        // delegate initial stake to validator owner
        // emit event
        emit ValidatorAdded(validatorAddress, validatorOwner, uint8(status), commissionRate);
    }

    function activateValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator memory validator = _validatorStorage.activate(validatorAddress);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function disableValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator memory validator = _validatorStorage.disable(validatorAddress);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function changeValidatorOwner(address validatorAddress, address newOwner) external override {
        require(_validatorStorage.isOwner(validatorAddress, msg.sender), "only owner");
        Validator memory validator = _validatorStorage.changeOwner(validatorAddress, newOwner);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validator.validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function _depositFee(address validatorAddress, uint256 amount) internal {
        // make sure validator is active
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        require(validator.status != ValidatorStatus.NotFound, "not found");
        uint64 epoch = currentEpoch();
        // increase total pending rewards for validator for current epoch
        ValidatorSnapshot storage currentSnapshot = _touchValidatorSnapshot(validator, epoch);
        currentSnapshot.totalRewards += uint96(amount);
        // validator data might be changed during _touchValidatorSnapshot()
        _addReward(validatorAddress, uint96(amount));
        // emit event
        emit ValidatorDeposited(validatorAddress, amount, epoch);
    }

    function _addReward(address validatorAddress, uint96 amount) internal virtual;

    function _addDelegate(address validatorAddress, uint112 amount, uint64 epoch) internal {
        // make sure validator exists at least
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        require(validator.status != ValidatorStatus.NotFound, "not found");
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + increase total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        ValidatorSnapshot storage validatorSnapshot = _touchValidatorSnapshot(validator, epoch);
        validatorSnapshot.totalDelegated += amount;
    }

    function _removeDelegate(address validatorAddress, uint112 amount, uint64 epoch) internal {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + decrease total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        _touchValidatorSnapshot(validator, epoch).safeDecreaseDelegated(amount);
    }

    function setValidatorStorage(address validatorStorage) external onlyFromGovernance {
        emit ValidatorStorageChanged(address(_validatorStorage), validatorStorage);
        _validatorStorage = IValidatorStorage(validatorStorage);
    }
}