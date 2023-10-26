// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {AccessControlEnumerable} from "openzeppelin/access/AccessControlEnumerable.sol";

import {IPauser, IPauserWrite, IPauserRead} from "./interfaces/IPauser.sol";
import {IOracle} from "./interfaces/IOracle.sol";

interface PauserEvents {
    /// @notice Emitted when a flag has been updated.
    /// @param selector The selector of the flag that was updated.
    /// @param isPaused The new value of the flag.
    /// @param flagName The name of the flag that was updated.
    event FlagUpdated(bytes4 indexed selector, bool indexed isPaused, string flagName);
}

/// @title Pauser
/// @notice Keeps the state of all actions that can be paused in case of exceptional circumstances. Pause state
/// is stored as boolean properties on the contract. This design was intentionally chosen to ensure there are explicit
/// compiler checks for the names and states of the different actions.
contract Pauser is Initializable, AccessControlEnumerableUpgradeable, IPauser, PauserEvents {
    // Errors.
    error PauserRoleOrOracleRequired(address sender);

    /// @notice Pauser role can pause flags in the contract.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Unpauser role can unpause flags in the contract.
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    /// @inheritdoc IPauserRead
    bool public isStakingPaused;

    /// @inheritdoc IPauserRead
    bool public isUnstakeRequestsAndClaimsPaused;

    /// @inheritdoc IPauserRead
    bool public isInitiateValidatorsPaused;

    /// @inheritdoc IPauserRead
    bool public isSubmitOracleRecordsPaused;

    /// @inheritdoc IPauserRead
    bool public isAllocateETHPaused;

    /// @notice Oracle contract which has permissions to pause the protocol.
    IOracle public oracle;

    /// @notice Configuration for contract initialization.
    struct Init {
        address admin;
        address pauser;
        address unpauser;
        IOracle oracle;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice Inititalizes the contract.
    /// @dev MUST be called during the contract upgrade to set up the proxies state.
    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        _grantRole(PAUSER_ROLE, init.pauser);
        _grantRole(UNPAUSER_ROLE, init.unpauser);

        oracle = init.oracle;
    }

    /// @notice Pauses or unpauses staking.
    /// @dev If pausing, checks if the caller has the pauser role. If unpausing,
    /// checks if the caller has the unpauser role.
    function setIsStakingPaused(bool isPaused) external onlyPauserUnpauserRole(isPaused) {
        _setIsStakingPaused(isPaused);
    }

    /// @notice Pauses or unpauses unstake requests.
    /// @dev If pausing, checks if the caller has the pauser role. If unpausing,
    /// checks if the caller has the unpauser role.
    function setIsUnstakeRequestsAndClaimsPaused(bool isPaused) external onlyPauserUnpauserRole(isPaused) {
        _setIsUnstakeRequestsAndClaimsPaused(isPaused);
    }

    /// @notice Pauses or unpauses initiate validators.
    /// @dev If pausing, checks if the caller has the pauser role. If unpausing,
    /// checks if the caller has the unpauser role.
    function setIsInitiateValidatorsPaused(bool isPaused) external onlyPauserUnpauserRole(isPaused) {
        _setIsInitiateValidatorsPaused(isPaused);
    }

    /// @notice Pauses or unpauses submit oracle records.
    /// @dev If pausing, checks if the caller has the pauser role. If unpausing,
    /// checks if the caller has the unpauser role.
    function setIsSubmitOracleRecordsPaused(bool isPaused) external onlyPauserUnpauserRole(isPaused) {
        _setIsSubmitOracleRecordsPaused(isPaused);
    }

    /// @notice Pauses or unpauses allocate ETH.
    /// @dev If pausing, checks if the caller has the pauser role. If unpausing,
    /// checks if the caller has the unpauser role.
    function setIsAllocateETHPaused(bool isPaused) external onlyPauserUnpauserRole(isPaused) {
        _setIsAllocateETHPaused(isPaused);
    }

    /// @inheritdoc IPauserWrite
    /// @dev Can be called by the oracle or any account with the pauser role.
    function pauseAll() external {
        _verifyPauserOrOracle();

        _setIsStakingPaused(true);
        _setIsUnstakeRequestsAndClaimsPaused(true);
        _setIsInitiateValidatorsPaused(true);
        _setIsSubmitOracleRecordsPaused(true);
        _setIsAllocateETHPaused(true);
    }

    /// @notice Unpauses all actions.
    function unpauseAll() external onlyRole(UNPAUSER_ROLE) {
        _setIsStakingPaused(false);
        _setIsUnstakeRequestsAndClaimsPaused(false);
        _setIsInitiateValidatorsPaused(false);
        _setIsSubmitOracleRecordsPaused(false);
        _setIsAllocateETHPaused(false);
    }

    function _verifyPauserOrOracle() internal view {
        if (hasRole(PAUSER_ROLE, msg.sender) || msg.sender == address(oracle)) {
            return;
        }
        revert PauserRoleOrOracleRequired(msg.sender);
    }

    // Internal setter functions.
    function _setIsStakingPaused(bool isPaused) internal {
        isStakingPaused = isPaused;
        emit FlagUpdated(this.isStakingPaused.selector, isPaused, "isStakingPaused");
    }

    function _setIsUnstakeRequestsAndClaimsPaused(bool isPaused) internal {
        isUnstakeRequestsAndClaimsPaused = isPaused;
        emit FlagUpdated(this.isUnstakeRequestsAndClaimsPaused.selector, isPaused, "isUnstakeRequestsAndClaimsPaused");
    }

    function _setIsInitiateValidatorsPaused(bool isPaused) internal {
        isInitiateValidatorsPaused = isPaused;
        emit FlagUpdated(this.isInitiateValidatorsPaused.selector, isPaused, "isInitiateValidatorsPaused");
    }

    function _setIsSubmitOracleRecordsPaused(bool isPaused) internal {
        isSubmitOracleRecordsPaused = isPaused;
        emit FlagUpdated(this.isSubmitOracleRecordsPaused.selector, isPaused, "isSubmitOracleRecordsPaused");
    }

    function _setIsAllocateETHPaused(bool isPaused) internal {
        isAllocateETHPaused = isPaused;
        emit FlagUpdated(this.isAllocateETHPaused.selector, isPaused, "isAllocateETHPaused");
    }

    modifier onlyPauserUnpauserRole(bool isPaused) {
        if (isPaused) {
            _checkRole(PAUSER_ROLE);
        } else {
            _checkRole(UNPAUSER_ROLE);
        }
        _;
    }
}