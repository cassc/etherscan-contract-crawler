// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev A contract for vesting ASM ASTO tokens for ASM employees.
 *
 * There are two types of schedules based on DelayType.
 *  - "Delay" schedules starts vesting tokens after a delay
 *     and tokens are only claimable after the 1st week of the delay
 *     period.
 *  - "Cliff" schedules vests tokens during the cliff period but
 *     they are unclaimable until the cliff has ended.
 *
 * The contract defining a tax-rate for schedules. Tax is reserved
 * in the contract vested tokens are claimed.
 *
 * The contract supports multiple vesting schedules for scenarios
 * when multiple schedules, tax-rates, updates are needed to be made.
 *
 * Schedules can be terminated any time after the last claimed date,
 * allowing tokens to be claimed until the termination timestamp.
 */
contract EmployeeTokenVesting is Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint256 internal constant SECONDS_PER_WEEK = 1 weeks;

    enum DelayType {
        Delay,
        Cliff
    }

    struct VestingSchedule {
        uint256 startTime;
        uint256 amount;
        DelayType delayType;
        uint16 durationInWeeks;
        uint16 delayInWeeks;
        uint16 taxRate100;
        uint256 totalClaimed;
        uint256 totalTaxClaimed;
        uint256 terminationTime;
    }

    struct AddVestingScheduleInput {
        uint256 startTime;
        uint256 amount;
        address recipient;
        DelayType delayType;
        uint16 durationInWeeks;
        uint16 delayInWeeks;
        uint16 taxRate100;
        uint256 totalClaimed;
        uint256 totalTaxClaimed;
    }

    struct VestedTokens {
        uint256 amount;
        uint256 tax;
    }

    event VestingAdded(
        uint256 vestingId,
        uint256 startTime,
        uint256 amount,
        address indexed recipient,
        uint16 durationInWeeks,
        uint16 delayInWeeks,
        uint16 taxRate100,
        DelayType delayType,
        uint256 _totalClaimed,
        uint256 _totalTaxClaimed
    );

    event VestingTokensClaimed(address indexed recipient, uint256 vestingId, uint256 amountClaimed, uint256 taxClaimed);
    event VestingRemoved(address indexed recipient, uint256 vestingId, uint256 amountVested, uint256 amountNotVested);
    event TaxWithdrawn(address indexed recipient, uint256 taxAmount);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    IERC20 public immutable token;

    mapping(address => mapping(uint256 => VestingSchedule)) public vestingSchedules;
    mapping(address => uint256) private vestingIds;

    uint256 public totalAllocatedAmount;
    uint256 public totalCollectedTax;

    address public proposedOwner;

    string constant INVALID_MULTISIG = "Invalid Multisig contract";
    string constant INVALID_TOKEN = "Invalid Token contract";
    string constant INSUFFICIENT_TOKEN_BALANCE = "Insufficient token balance";
    string constant NO_TOKENS_VESTED_PER_WEEK = "No token vested per week";
    string constant INVALID_START_TIME = "Invalid start time";
    string constant INVALID_DURATION = "Invalid duration";
    string constant INVALID_TAX_RATE = "Invlaid tax rate";
    string constant INVALID_CLIFF_DURATION = "Invalid cliff duration";
    string constant NO_ACTIVE_VESTINGS = "No active vestings";
    string constant INVALID_VESTING_ID = "Invalid vestingId";
    string constant NO_TOKENS_VESTED = "No tokens vested";
    string constant TERMINATION_TIME_BEFORE_LAST_CLAIM = "Terminate before the last claim";
    string constant TERMINATION_TIME_BEFORE_START_TIME = "Terminate before the start time";
    string constant ERROR_CALLER_ALREADY_OWNER = "Already owner";
    string constant ERROR_NOT_PROPOSED_OWNER = "Not proposed owner";
    string constant MAX_ADD_LIMIT = "Can only add 30 max";
    string constant NO_SHEDULES_TO_ADD = "No schedules to add";
    string constant INVALID_PARTIAL_VESTING = "Total claimed more than amount";

    constructor(IERC20 _token, address multisig) {
        require(address(multisig) != address(0), INVALID_MULTISIG);
        require(address(_token) != address(0), INVALID_TOKEN);
        token = _token;

        _transferOwnership(multisig);
    }

    /**
     * @notice Add a new vesting schedule for a recipient address.
     *         for _delayType Cliff vesting, _durationInWeeks need be greater than _delayInWeeks.
     *
     * @param _recipient recipient of the vested tokens from the schedule
     * @param _startTime starting time for vesting schedule, including any delays
     * @param _amount amount to vest over the vesting duration
     * @param _durationInWeeks duration of the vesting schedule in weeks
     * @param _delayInWeeks delay/cliff of the vesting schedule in weeks
     * @param _taxRate100 tax rate, multiplied by 100 to allow fractionals
     * @param _delayType type of the schedule delay Delay/Cliff
     */
    function addVestingSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks,
        uint16 _taxRate100,
        DelayType _delayType,
        uint256 _totalClaimed,
        uint256 _totalTaxClaimed
    ) public onlyOwner {
        uint256 availableBalance = token.balanceOf(address(this)) - totalAllocatedAmount;
        require(_amount <= availableBalance, INSUFFICIENT_TOKEN_BALANCE);
        require(_durationInWeeks > 0, INVALID_DURATION);
        require((_totalClaimed + _totalTaxClaimed) <= _amount, INVALID_PARTIAL_VESTING);

        uint256 amountVestedPerWeek = _amount / _durationInWeeks;
        require(amountVestedPerWeek > 0, NO_TOKENS_VESTED_PER_WEEK);
        require(_startTime > 0, INVALID_START_TIME);
        require(_taxRate100 <= 10000, INVALID_TAX_RATE);

        if (_delayType == DelayType.Cliff) {
            require(_durationInWeeks > _delayInWeeks, INVALID_CLIFF_DURATION);
        }

        VestingSchedule memory vesting = VestingSchedule({
            startTime: _startTime,
            amount: _amount,
            durationInWeeks: _durationInWeeks,
            delayType: _delayType,
            delayInWeeks: _delayInWeeks,
            totalClaimed: _totalClaimed,
            totalTaxClaimed: _totalTaxClaimed,
            taxRate100: _taxRate100,
            terminationTime: 0
        });

        uint256 vestingId = vestingIds[_recipient];

        require(vestingId < 100, "Maximum vesting schedules for recipient reached");

        vestingSchedules[_recipient][vestingId] = vesting;
        vestingIds[_recipient] = vestingId + 1;

        emit VestingAdded(
            vestingId,
            vesting.startTime,
            _amount,
            _recipient,
            _durationInWeeks,
            _delayInWeeks,
            _taxRate100,
            _delayType,
            _totalClaimed,
            _totalTaxClaimed
        );

        // If the schedule is already partially claimed, reduce that amout from the total
        totalAllocatedAmount += (_amount - grossClaimed(vesting));
    }

    /**
     * @notice Add multiple vesting schedules. Refer to addVestingSchedule for indevidual argument reference.
     * @param schedules Array of schedules with max 30 elements.
     */
    function addVestingSchedules(AddVestingScheduleInput[] calldata schedules) public onlyOwner {
        require(schedules.length <= 30, MAX_ADD_LIMIT);
        require(schedules.length > 0, NO_SHEDULES_TO_ADD);

        for (uint256 idx = 0; idx < schedules.length; ++idx) {
            addVestingSchedule(
                schedules[idx].recipient,
                schedules[idx].startTime,
                schedules[idx].amount,
                schedules[idx].durationInWeeks,
                schedules[idx].delayInWeeks,
                schedules[idx].taxRate100,
                schedules[idx].delayType,
                schedules[idx].totalClaimed,
                schedules[idx].totalTaxClaimed
            );
        }
    }

    /**
     * @notice Get the vesting schedlue couunt per recipient.
     * @param _recipient recipient for vesting schedules.
     * @return uint256 count
     */
    function getVestingCount(address _recipient) public view returns (uint256) {
        return vestingIds[_recipient];
    }

    /**
     * @notice Calculate vesting claims of all schedules for recipient.
     * @param _recipient recipient for vesting schedules.
     * @return VestedTokens vested token amount and tax.
     */
    function calculateTotalVestingClaim(address _recipient) public view returns (VestedTokens memory) {
        uint256 vestingCount = vestingIds[_recipient];
        require(vestingCount > 0, NO_ACTIVE_VESTINGS);

        uint256 totalAmountVested;
        uint256 vestedTax;

        for (uint256 _vestingId = 0; _vestingId < vestingCount; ++_vestingId) {
            VestedTokens memory vested = calculateVestingClaim(_recipient, _vestingId);

            totalAmountVested += vested.amount;
            vestedTax += vested.tax;
        }

        return VestedTokens({amount: totalAmountVested, tax: vestedTax});
    }

    /**
     * @notice Calculate vesting claim per vesting schedule.
     * @param _recipient recipient for vesting schedules.
     * @param _vestingId vesting schedule id (incrementing numnber based on count).
     * @return VestedTokens vested token amount and tax.
     */
    function calculateVestingClaim(address _recipient, uint256 _vestingId) public view returns (VestedTokens memory) {
        VestingSchedule storage vestingSchedule = vestingSchedules[_recipient][_vestingId];
        require(vestingSchedule.startTime > 0, INVALID_VESTING_ID);

        return _calculateVestingClaim(vestingSchedule);
    }

    /**
     * @notice Calculate vesting claim per vesting schedule.
     * @param vestingSchedule vesting schedule to calculate the vested amount.
     * @return VestedTokens vested token amount and tax.
     */
    function _calculateVestingClaim(VestingSchedule storage vestingSchedule)
        internal
        view
        returns (VestedTokens memory)
    {
        uint256 grossAmountVested = _calculateVestingClaimAtTime(vestingSchedule, currentTime());
        uint256 tax = calculateTax(grossAmountVested, vestingSchedule.taxRate100);

        return VestedTokens({amount: grossAmountVested - tax, tax: tax});
    }

    /**
     * @notice Calculate the vesting claim at the time for a scedule.
     * @param vestingSchedule vesting schedule to calculate the vested amount.
     * @param _currentTime time to calculate the vesting on.
     * @return uint256 vested gross token amount.
     */
    function _calculateVestingClaimAtTime(VestingSchedule storage vestingSchedule, uint256 _currentTime)
        internal
        view
        returns (uint256)
    {
        uint256 effectiveCurrentTime = vestingSchedule.terminationTime == 0
            ? _currentTime
            : Math.min(_currentTime, vestingSchedule.terminationTime);

        if (effectiveCurrentTime < vestingSchedule.startTime) {
            return 0;
        }

        uint256 elapsedTime = effectiveCurrentTime - vestingSchedule.startTime;
        uint256 elapsedTimeInWeeks = elapsedTime / SECONDS_PER_WEEK;

        // in both Cliff and Delay, nothing can be vested until the delay period
        if (elapsedTimeInWeeks < vestingSchedule.delayInWeeks) {
            return 0;
        }

        // Cliifs are vested during the delay, Delays are added to the duration
        uint256 effectiveDuration = vestingSchedule.delayType == DelayType.Delay
            ? vestingSchedule.durationInWeeks + vestingSchedule.delayInWeeks
            : vestingSchedule.durationInWeeks;

        if (elapsedTimeInWeeks >= effectiveDuration) {
            uint256 remainingVesting = vestingSchedule.amount - grossClaimed(vestingSchedule);

            return remainingVesting;
        } else {
            // Cliifs are vested during the delay, Delays are added to the duration
            uint16 claimableWeeks = vestingSchedule.delayType == DelayType.Delay
                ? uint16(elapsedTimeInWeeks - vestingSchedule.delayInWeeks)
                : uint16(elapsedTimeInWeeks);

            uint256 amountVestedPerWeek = vestingSchedule.amount / vestingSchedule.durationInWeeks;
            uint256 claimableAmount = claimableWeeks * amountVestedPerWeek;

            // This happens if the shedule was already partially vested when its added.
            if (grossClaimed(vestingSchedule) > claimableAmount) {
                return 0;
            }

            uint256 amountVested = claimableAmount - grossClaimed(vestingSchedule);

            return amountVested;
        }
    }

    /**
     * @notice Claim vested tokens and send to recipient's address.
     *         msg.sender is the recipient.
     * @dev    Need to have atleast 1 active vesting, and vest at leat 1 token to be successful.
     */
    function claimVestedTokens() external {
        require(!paused(), "claimVestedTokens() is not enabled");

        uint256 vestingCount = vestingIds[msg.sender];
        require(vestingCount > 0, NO_ACTIVE_VESTINGS);

        uint256 totalAmountVested;
        uint256 vestedTax;

        for (uint256 _vestingId = 0; _vestingId < vestingCount; ++_vestingId) {
            VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender][_vestingId];

            VestedTokens memory tokensVested = _calculateVestingClaim(vestingSchedule);

            vestingSchedule.totalClaimed = uint256(vestingSchedule.totalClaimed + tokensVested.amount);
            vestingSchedule.totalTaxClaimed = uint256(vestingSchedule.totalTaxClaimed + tokensVested.tax);

            totalAmountVested += tokensVested.amount;
            vestedTax += tokensVested.tax;
        }

        require(token.balanceOf(address(this)) >= totalAmountVested, NO_TOKENS_VESTED);

        totalCollectedTax += vestedTax;
        totalAllocatedAmount -= totalAmountVested;

        token.safeTransfer(msg.sender, totalAmountVested);
        emit VestingTokensClaimed(msg.sender, vestingCount, totalAmountVested, vestedTax);
    }

    /**
     * @notice Terminate vesting shedule by recipient and vestingId.
     * @param _recipient recipient for vesting schedules.
     * @param _vestingId vesting schedule id (incrementing numnber based on count).
     * @param _terminationTime time the shedule would terminate at.
     *
     * @dev Terminating time should be after start date and the last date vesing is claimed.
     */
    function terminateVestingSchedule(
        address _recipient,
        uint256 _vestingId,
        uint256 _terminationTime
    ) external onlyOwner {
        VestingSchedule storage vestingSchedule = vestingSchedules[_recipient][_vestingId];

        require(vestingSchedule.startTime > 0, INVALID_VESTING_ID);

        uint256 lastVestedTime = _calculateLastVestedTimestamp(vestingSchedule);

        require(_terminationTime >= lastVestedTime, TERMINATION_TIME_BEFORE_LAST_CLAIM);
        require(_terminationTime >= vestingSchedule.startTime, TERMINATION_TIME_BEFORE_START_TIME);

        uint256 grossAmountToBeVested = _calculateVestingClaimAtTime(vestingSchedule, _terminationTime);

        uint256 amountIneligibleForVesting = vestingSchedule.amount -
            (grossClaimed(vestingSchedule) + grossAmountToBeVested);

        vestingSchedule.terminationTime = _terminationTime;

        totalAllocatedAmount -= amountIneligibleForVesting;
        emit VestingRemoved(_recipient, _vestingId, grossAmountToBeVested, amountIneligibleForVesting);
    }

    function _calculateLastVestedTimestamp(VestingSchedule storage vestingSchedule) internal view returns (uint256) {
        if (vestingSchedule.totalClaimed == 0) {
            return vestingSchedule.startTime;
        }

        uint256 amountVestedPerWeek = vestingSchedule.amount / vestingSchedule.durationInWeeks;
        uint256 weeksClaimed = grossClaimed(vestingSchedule) / amountVestedPerWeek;

        uint256 effectiveDelayInWeeks = vestingSchedule.delayType == DelayType.Delay ? vestingSchedule.delayInWeeks : 0;
        return vestingSchedule.startTime + effectiveDelayInWeeks + (weeksClaimed * SECONDS_PER_WEEK);
    }

    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /**
     * @notice Calculate tokens vested per-week, for a schedule by vestingId
     * @param _recipient recipient for vesting schedules.
     * @param _vestingId vesting schedule id (incrementing numnber based on count).
     * @return VestedTokens vested tokens and tax per week.
     */
    function tokensVestedPerWeek(address _recipient, uint256 _vestingId) public view returns (VestedTokens memory) {
        VestingSchedule storage vestingSchedule = vestingSchedules[_recipient][_vestingId];
        require(vestingSchedule.startTime > 0, INVALID_VESTING_ID);

        uint256 gross = vestingSchedule.amount / vestingSchedule.durationInWeeks;
        uint256 tax = (gross * vestingSchedule.taxRate100) / 10000;
        return VestedTokens({amount: gross - tax, tax: tax});
    }

    /**
     * @dev Calculate the gross amount including both claimed and tax.
     * @param vestingSchedule vesting schedule to calculate the gross claimed amount
     */
    function grossClaimed(VestingSchedule memory vestingSchedule) internal pure returns (uint256) {
        return vestingSchedule.totalClaimed + vestingSchedule.totalTaxClaimed;
    }

    /**
     * @dev Calcualte tax for gross amount.
     * @param gross gross amount to be claimed
     * @param taxRate100 Percentage tax rate * 100
     */
    function calculateTax(uint256 gross, uint256 taxRate100) internal pure returns (uint256) {
        return (gross * taxRate100) / 10000;
    }

    /**
     * @notice Withdraw tax collected in the contract.
     * @param recipient recipient for vesting schedules.
     */
    function withdrawTax(address recipient) external onlyOwner {
        require(recipient != address(0), INVALID_TOKEN);

        uint256 balance = token.balanceOf(address(this));

        require(totalCollectedTax <= (balance - totalAllocatedAmount), INSUFFICIENT_TOKEN_BALANCE);

        uint256 taxClaimable = totalCollectedTax;
        totalCollectedTax = 0;
        totalAllocatedAmount -= taxClaimable;

        token.safeTransfer(recipient, taxClaimable);
        emit TaxWithdrawn(recipient, taxClaimable);
    }

    /**
     * @notice Withdraw tokens that are not allocated for a vesting schedule.
     * @param recipient recipient for vesting schedules.
     */
    function withdrawUnAllocatedToken(address recipient) external onlyOwner {
        require(recipient != address(0), INVALID_TOKEN);

        uint256 balance = token.balanceOf(address(this));
        uint256 unAllocatedAmount = balance - totalAllocatedAmount;

        require(unAllocatedAmount > 0, INSUFFICIENT_TOKEN_BALANCE);

        token.safeTransfer(recipient, unAllocatedAmount);
        emit TokenWithdrawn(recipient, unAllocatedAmount);
    }

    /**
     * @notice WARNING! withdraw tokens remaining in the contract. Used for migrating contracts.
     * @param recipient recipient for vesting schedules.
     * @param amount amount to withdraw from the contract.
     */
    function withdrawToken(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), INVALID_TOKEN);
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, INSUFFICIENT_TOKEN_BALANCE);
        token.safeTransfer(recipient, amount);
        emit TokenWithdrawn(recipient, amount);
    }

    /**
     * @notice Propose a new owner of the contract.
     * @param _proposedOwner The proposed new owner of the contract.
     */
    function proposeOwner(address _proposedOwner) external onlyOwner {
        require(msg.sender != _proposedOwner, ERROR_CALLER_ALREADY_OWNER);
        proposedOwner = _proposedOwner;
    }

    /**
     * @notice Claim ownership by calling the function as the proposed owner.
     */
    function claimOwnership() external {
        require(address(proposedOwner) != address(0), INVALID_MULTISIG);
        require(msg.sender == proposedOwner, ERROR_NOT_PROPOSED_OWNER);

        emit OwnershipTransferred(owner(), proposedOwner);
        _transferOwnership(proposedOwner);
        proposedOwner = address(0);
    }

    /**
     * @notice Pause the claiming process
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the claiming process
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}