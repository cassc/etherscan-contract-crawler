// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './interfaces/IPenalty.sol';
import './interfaces/IRatedV1.sol';
import './interfaces/IStaderOracle.sol';
import './interfaces/IStaderConfig.sol';

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract Penalty is IPenalty, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    IStaderConfig public staderConfig;
    address public override ratedOracleAddress;
    uint256 public override mevTheftPenaltyPerStrike;
    uint256 public override missedAttestationPenaltyPerStrike;
    uint256 public override validatorExitPenaltyThreshold;

    /// @inheritdoc IPenalty
    mapping(bytes32 => uint256) public override additionalPenaltyAmount;
    /// @inheritdoc IPenalty
    mapping(bytes => uint256) public override totalPenaltyAmount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _staderConfig,
        address _ratedOracleAddress
    ) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);
        UtilLib.checkNonZeroAddress(_ratedOracleAddress);
        __AccessControl_init_unchained();
        __ReentrancyGuard_init();

        staderConfig = IStaderConfig(_staderConfig);
        ratedOracleAddress = _ratedOracleAddress;
        mevTheftPenaltyPerStrike = 1 ether;
        missedAttestationPenaltyPerStrike = 0.2 ether;
        validatorExitPenaltyThreshold = 2 ether;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        emit UpdatedPenaltyOracleAddress(_ratedOracleAddress);
    }

    /// @inheritdoc IPenalty
    function setAdditionalPenaltyAmount(bytes calldata _pubkey, uint256 _amount) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        bytes32 pubkeyRoot = UtilLib.getPubkeyRoot(_pubkey);
        additionalPenaltyAmount[pubkeyRoot] += _amount;

        emit UpdatedAdditionalPenaltyAmount(_pubkey, _amount);
    }

    /// @inheritdoc IPenalty
    function updateMEVTheftPenaltyPerStrike(uint256 _mevTheftPenaltyPerStrike) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        mevTheftPenaltyPerStrike = _mevTheftPenaltyPerStrike;
        emit UpdatedMEVTheftPenaltyPerStrike(_mevTheftPenaltyPerStrike);
    }

    /// @inheritdoc IPenalty
    function updateMissedAttestationPenaltyPerStrike(uint256 _missedAttestationPenaltyPerStrike) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        missedAttestationPenaltyPerStrike = _missedAttestationPenaltyPerStrike;
        emit UpdatedMissedAttestationPenaltyPerStrike(_missedAttestationPenaltyPerStrike);
    }

    /// @inheritdoc IPenalty
    function updateValidatorExitPenaltyThreshold(uint256 _validatorExitPenaltyThreshold) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        validatorExitPenaltyThreshold = _validatorExitPenaltyThreshold;
        emit UpdatedValidatorExitPenaltyThreshold(_validatorExitPenaltyThreshold);
    }

    /// @inheritdoc IPenalty
    function updateRatedOracleAddress(address _ratedOracleAddress) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        UtilLib.checkNonZeroAddress(_ratedOracleAddress);
        ratedOracleAddress = _ratedOracleAddress;
        emit UpdatedPenaltyOracleAddress(_ratedOracleAddress);
    }

    //update the address of staderConfig
    function updateStaderConfig(address _staderConfig) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /// @inheritdoc IPenalty
    function updateTotalPenaltyAmount(bytes[] calldata _pubkey) external override nonReentrant {
        uint256 reportedValidatorCount = _pubkey.length;
        for (uint256 i; i < reportedValidatorCount; ) {
            if (UtilLib.getValidatorSettleStatus(_pubkey[i], staderConfig)) {
                revert ValidatorSettled();
            }
            bytes32 pubkeyRoot = UtilLib.getPubkeyRoot(_pubkey[i]);
            // Retrieve the penalty for changing the fee recipient address based on Rated.network data.
            uint256 _mevTheftPenalty = calculateMEVTheftPenalty(pubkeyRoot);
            uint256 _missedAttestationPenalty = calculateMissedAttestationPenalty(pubkeyRoot);

            // Compute the total penalty for the given validator public key,
            // taking into account additional penalties and penalty reversals from the DAO.
            uint256 totalPenalty = _mevTheftPenalty + _missedAttestationPenalty + additionalPenaltyAmount[pubkeyRoot];
            totalPenaltyAmount[_pubkey[i]] = totalPenalty;
            if (totalPenalty >= validatorExitPenaltyThreshold) {
                emit ForceExitValidator(_pubkey[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IPenalty
    function calculateMEVTheftPenalty(bytes32 _pubkeyRoot) public override returns (uint256) {
        // Retrieve the epochs in which the validator violated the fee recipient change rule.
        uint256[] memory violatedEpochs = IRatedV1(ratedOracleAddress).getViolationsForValidator(_pubkeyRoot);

        // each strike attracts `mevTheftPenaltyPerStrike` penalty
        return violatedEpochs.length * mevTheftPenaltyPerStrike;
    }

    /// @inheritdoc IPenalty
    function calculateMissedAttestationPenalty(bytes32 _pubkeyRoot) public view override returns (uint256) {
        return
            IStaderOracle(staderConfig.getStaderOracle()).missedAttestationPenalty(_pubkeyRoot) *
            missedAttestationPenaltyPerStrike;
    }

    /// @inheritdoc IPenalty
    function getAdditionalPenaltyAmount(bytes calldata _pubkey) external view override returns (uint256) {
        return additionalPenaltyAmount[UtilLib.getPubkeyRoot(_pubkey)];
    }

    /// @inheritdoc IPenalty
    function markValidatorSettled(uint8 _poolId, uint256 _validatorId) external override {
        bytes memory pubkey = UtilLib.getPubkeyForValidSender(_poolId, _validatorId, msg.sender, staderConfig);
        totalPenaltyAmount[pubkey] = 0;
        emit ValidatorMarkedAsSettled(pubkey);
    }
}