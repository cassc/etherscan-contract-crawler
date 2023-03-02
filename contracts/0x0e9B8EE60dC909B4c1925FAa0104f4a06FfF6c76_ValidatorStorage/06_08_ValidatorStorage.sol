// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IStakingConfig.sol";

import "../libs/ValidatorUtil.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IValidatorStorage.sol";

contract ValidatorStorage is Initializable, IValidatorStorage {

    event StakingPoolChanged(address prevValue, address newValue);

    // mapping from validator address to validator
    mapping(address => Validator) internal _validatorsMap;
    // mapping from validator owner to validator address
    mapping(address => address) public validatorOwners;
    // list of all validators that are in validators mapping
    address[] public activeValidatorsList;
    // chain config with params
    IStakingConfig internal _stakingConfig;
    IStaking internal _stakingPool;
    // reserve some gap for the future upgrades
    uint256[50 - 5] private __reserved;

    modifier onlyFromGovernance() virtual {
        require(msg.sender == _stakingConfig.getGovernanceAddress(), "ValidatorStorage: only governance");
        _;
    }

    modifier onlyFromPool() virtual {
        require(msg.sender == address(_stakingPool), "ValidatorStorage: only pool");
        _;
    }

    function initialize(IStakingConfig stakingConfig, IStaking stakingPool) external initializer {
        __ValidatorStorage_init(stakingConfig, stakingPool);
    }

    function __ValidatorStorage_init(IStakingConfig stakingConfig, IStaking stakingPool) internal {
        _stakingConfig = stakingConfig;
        _stakingPool = stakingPool;
    }

    function getStakingConfig() external view virtual returns (IStakingConfig) {
        return _stakingConfig;
    }

    function getValidator(address validatorAddress) external view returns (Validator memory) {
        return _validatorsMap[validatorAddress];
    }

    function migrate(Validator calldata validator) external override onlyFromPool {
        _validatorsMap[validator.validatorAddress] = validator;
        validatorOwners[validator.ownerAddress] = validator.validatorAddress;
        if (validator.status == ValidatorStatus.Active) {
            activeValidatorsList.push(validator.validatorAddress);
        }
    }

    function create(
        address validatorAddress,
        address validatorOwner,
        ValidatorStatus status,
        uint64 epoch
    ) external override onlyFromPool {
        require(status != ValidatorStatus.NotFound, "ValidatorStorage: status not allowed");
        Validator storage self = _validatorsMap[validatorAddress];
        require(self.status == ValidatorStatus.NotFound, "ValidatorStorage: already exist");
        self.validatorAddress = validatorAddress;
        self.ownerAddress = validatorOwner;
        self.status = status;
        self.changedAt = epoch;

        // save validator owner
        require(validatorOwners[validatorOwner] == address(0x00), "owner in use");
        validatorOwners[validatorOwner] = validatorAddress;

        // add new validator to array
        if (status == ValidatorStatus.Active) {
            activeValidatorsList.push(validatorAddress);
        }
    }

    function activate(address validatorAddress) external override onlyFromPool returns (Validator memory) {
        Validator storage self = _validatorsMap[validatorAddress];
        require(self.status == ValidatorStatus.Pending, "Validator: bad status");
        self.status = ValidatorStatus.Active;

        activeValidatorsList.push(validatorAddress);

        return self;
    }

    function change(address validatorAddress, uint64 epoch) external override onlyFromPool {
        _validatorsMap[validatorAddress].changedAt = epoch;
    }

    function disable(address validatorAddress) external override onlyFromPool returns (Validator memory) {
        Validator storage self = _validatorsMap[validatorAddress];
        require(self.status == ValidatorStatus.Active || self.status == ValidatorStatus.Jail, "Validator: bad status");
        self.status = ValidatorStatus.Pending;

        _removeValidatorFromActiveList(validatorAddress);

        return self;
    }

    function _removeValidatorFromActiveList(address validatorAddress) internal onlyFromPool {
        // find index of validator in validator set
        int256 indexOf = - 1;
        for (uint256 i; i < activeValidatorsList.length; i++) {
            if (activeValidatorsList[i] != validatorAddress) continue;
            indexOf = int256(i);
            break;
        }
        // remove validator from array (since we remove only active it might not exist in the list)
        if (indexOf >= 0) {
            if (activeValidatorsList.length > 1 && uint256(indexOf) != activeValidatorsList.length - 1) {
                activeValidatorsList[uint256(indexOf)] = activeValidatorsList[activeValidatorsList.length - 1];
            }
            activeValidatorsList.pop();
        }
    }

    function changeOwner(address validatorAddress, address newOwner) external override onlyFromPool returns (Validator memory) {
        require(newOwner != address(0x0), "new owner cannot be zero address");
        Validator storage validator = _validatorsMap[validatorAddress];
        require(validatorOwners[newOwner] == address(0x00), "owner in use");
        delete validatorOwners[validator.ownerAddress];
        validator.ownerAddress = newOwner;
        validatorOwners[newOwner] = validatorAddress;

        return validator;
    }

    function isValidatorActive(address account) external view returns (bool) {
        if (!isActive(account)) {
            return false;
        }
        address[] memory topValidators = getValidators();
        for (uint256 i; i < topValidators.length; i++) {
            if (topValidators[i] == account) return true;
        }
        return false;
    }

    function isValidator(address account) external view returns (bool) {
        return _validatorsMap[account].status != ValidatorStatus.NotFound;
    }

    function isActive(address validatorAddress) public view returns (bool) {
        return _validatorsMap[validatorAddress].status == ValidatorStatus.Active;
    }

    function isOwner(address validatorAddress, address addr) external view override returns (bool) {
        return _validatorsMap[validatorAddress].ownerAddress == addr;
    }

    function getValidators() public view override returns (address[] memory) {
        return activeValidatorsList;
    }
}