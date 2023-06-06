// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (VestingWalletMultiLinear.sol)
pragma solidity 0.8.12;

import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Lockable.sol";

/**
 * @title VestingWalletMultiLinear
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the schedule functions: {addToSchedule} and {resetSchedule}.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 *
 * Each schedule step defines how many token will be released for a given duration.
 * For a step, the release is a linear vesting curve.
 *
 * The contract can be paused by PAUSER_ROLE. When contract is paused, token can't be released.
 * The beneficiary is editable by BENEFICIARY_MANAGER_ROLE.
 * The schedule is editable by SCHEDULE_MANAGER_ROLE when the contract is not locked.
 *
 * @custom:security-contact [email protected]
 */
contract VestingWalletMultiLinear is
    VestingWallet,
    IERC777Recipient,
    Pausable,
    AccessControlEnumerable,
    Lockable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SCHEDULE_MANAGER_ROLE =
        keccak256("SCHEDULE_MANAGER_ROLE");
    bytes32 public constant BENEFICIARY_MANAGER_ROLE =
        keccak256("BENEFICIARY_MANAGER_ROLE");

    IERC1820Registry internal constant _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    struct ScheduleStep {
        uint8 percent;
        uint256 start;
        uint64 duration;
    }

    ScheduleStep[] private _sortedSchedule;
    uint8 private _stepPercentSum;
    address private _beneficiary;
    uint64 private _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     * Register ERC1820 interface implementer
     * Setup roles
     */
    constructor(address beneficiaryAddress, uint64 startTimestamp)
        VestingWallet(beneficiaryAddress, startTimestamp, 0)
    {
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(SCHEDULE_MANAGER_ROLE, msg.sender);
        _grantRole(BENEFICIARY_MANAGER_ROLE, msg.sender);

        setBeneficiary(beneficiaryAddress);
    }

    /**
     * @dev See {IERC777Recipient-tokensReceived}.
     */
    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external override {}

    /**
     * @dev Pause token releases.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause token releases.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Lock schedule edition for a duration.
     *
     * Requirements:
     *
     * - Caller must have role DEFAULT_ADMIN_ROLE.
     */
    function lock(uint256 lockDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _lock(lockDuration);
    }

    /**
     * @dev Permanently lock schedule edition.
     *
     * Requirements:
     *
     * - Caller must have role DEFAULT_ADMIN_ROLE.
     */
    function permanentLock() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _permanentLock();
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view override returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Setter for the beneficiary address.
     * Emits a {BeneficiaryEdited} event.
     *
     * Requirements:
     *
     * - Caller must have role BENEFICIARY_MANAGER_ROLE.
     */
    function setBeneficiary(address beneficiaryAddress)
        public
        onlyRole(BENEFICIARY_MANAGER_ROLE)
    {
        require(
            beneficiaryAddress != address(0),
            "VestingWalletMultiLinear: beneficiary is zero address"
        );
        _beneficiary = beneficiaryAddress;

        emit BeneficiaryEdited(beneficiaryAddress);
    }

    /**
     * @dev Add a step to the schedule.
     * Emits a {ScheduleStepAdded} event.
     *
     * Requirements:
     *
     * - Caller must have role SCHEDULE_MANAGER_ROLE.
     * - step percent sum should not go above 100.
     */
    function addToSchedule(uint8 stepPercent, uint64 stepDuration)
        external
        onlyRole(SCHEDULE_MANAGER_ROLE)
        whenNotLocked
    {
        require(
            _stepPercentSum + stepPercent <= 100,
            "VestingWalletMultiLinear: stepPercentSum above 100. Double check schedule and/or rebuild it."
        );
        _sortedSchedule.push(
            ScheduleStep(stepPercent, start() + duration(), stepDuration)
        );
        _stepPercentSum += stepPercent;
        _duration += stepDuration;

        emit ScheduleStepAdded(stepPercent, stepDuration);
    }

    /**
     * @dev Delete all steps of the schedule.
     * Emits a {ScheduleReset} event.
     *
     * Requirements:
     *
     * - Caller must have role SCHEDULE_MANAGER_ROLE.
     * - The contract must not be locked.
     */
    function resetSchedule()
        external
        onlyRole(SCHEDULE_MANAGER_ROLE)
        whenNotLocked
    {
        delete _sortedSchedule;
        _stepPercentSum = 0;
        _duration = 0;

        emit ScheduleReset();
    }

    /**
     * @dev Getter for the step percent sum.
     */
    function stepPercentSum() external view returns (uint8) {
        return _stepPercentSum;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view override returns (uint256) {
        return _duration;
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {TokensReleased} event.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function release() public override whenNotPaused {
        super.release();
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function release(address token) public override whenNotPaused {
        super.release(token);
    }

    /**
     * @dev Implementation of the vesting formula. This returns the amount vested,
     * as a function of time, for an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        override
        returns (uint256)
    {
        require(
            _sortedSchedule.length > 0,
            "VestingWalletMultiLinear: Schedule is empty. Call addToSchedule(uint8 stepPercent, uint64 stepDuration) first."
        );

        uint256 amountVested = 0;
        uint256 index = 0;
        ScheduleStep storage currentStep;
        do {
            currentStep = _sortedSchedule[index];
            amountVested += _vestingScheduleAtStep(
                currentStep,
                totalAllocation,
                timestamp
            );
            index += 1;
        } while (
            timestamp > currentStep.start && index < _sortedSchedule.length
        );

        return amountVested;
    }

    /**
     * @dev Implementation of the vesting formula for a given step. This returns the amount vested,
     * as a linear function of time, for an asset given its total historical allocation.
     */
    function _vestingScheduleAtStep(
        ScheduleStep storage step,
        uint256 totalAllocation,
        uint64 timestamp
    ) private view returns (uint256) {
        uint256 stepAllocation = (totalAllocation * step.percent) / 100;

        if (timestamp < step.start) {
            return 0;
        } else if (timestamp >= step.start + step.duration) {
            return stepAllocation;
        } else {
            return (stepAllocation * (timestamp - step.start)) / step.duration;
        }
    }

    event BeneficiaryEdited(address beneficiaryAddress);

    event ScheduleReset();

    event ScheduleStepAdded(uint8 stepPercent, uint64 stepDuration);
}