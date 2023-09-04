// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/// @title TokenVesting - On-Chain vesting scheme enabled by smart contracts.
/// The TokenVesting contract can release its token balance gradually like a
/// typical vesting scheme, with a cliff and vesting period. The contract owner
/// can create vesting schedules for different users, even multiple for the same person.
/// Vesting schedules are optionally revokable by the owner. Additionally the
/// smart contract functions as an ERC20 compatible non-transferable virtual
/// token which can be used e.g. for governance.
/// This work is based on the TokenVesting contract by Abdelhamid Bakhta
/// (https://github.com/abdelhamidbakhta/token-vesting-contracts)
/// and was extended with the virtual token functionality and partially rewritten.
/// @author Schmackofant - [email protected]

contract TokenVesting is IERC20Metadata, Ownable, ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20Metadata;

    /// @notice The ERC20 name of the virtual token
    string public override name;

    /// @notice The ERC20 symbol of the virtual token
    string public override symbol;

    /// @notice The ERC20 number of decimals of the virtual token
    /// @dev This contract only supports native tokens with 18 decimals
    uint8 public constant override decimals = 18;

    enum Status {
        INITIALIZED, //0
        REVOKED
    }

    /**
     * @dev vesting schedule struct
     * @param cliff cliff period in seconds
     * @param start start time of the vesting period
     * @param duration duration of the vesting period in seconds
     * @param slicePeriodSeconds duration of a slice period for the vesting in seconds
     * @param amountTotal total amount of tokens to be released at the end of the vesting
     * @param released amount of tokens released so far
     * @param status schedule status (initialized, revoked)
     * @param beneficiary address of beneficiary of the vesting schedule
     * @param revokable whether or not the vesting is revokable
     */
    struct VestingSchedule {
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriodSeconds;
        uint256 amountTotal;
        uint256 released;
        Status status;
        address beneficiary;
        bool revokable;
    }

    /// @notice address of the ERC20 native token
    IERC20Metadata public immutable nativeToken;

    /// @dev This mapping is used to keep track of the vesting schedule ids
    bytes32[] public vestingSchedulesIds;

    /// @dev This mapping is used to keep track of the vesting schedules
    mapping(bytes32 => VestingSchedule) private vestingSchedules;

    /// @notice total amount of native tokens in all vesting schedules
    uint256 public vestingSchedulesTotalAmount;

    /// @notice This mapping is used to keep track of the number of vesting schedules for each beneficiary
    mapping(address => uint256) public holdersVestingScheduleCount;

    /// @dev This mapping is used to keep track of the total amount of vested tokens for each beneficiary
    mapping(address => uint256) private holdersVestedAmount;

    bytes32 public constant ROLE_CREATE_SCHEDULE = keccak256("ROLE_CREATE_SCHEDULE");

    event ScheduleCreated(
        bytes32 indexed scheduleId,
        address indexed beneficiary,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 slicePeriodSeconds,
        bool revokable
    );
    event TokensReleased(bytes32 indexed scheduleId, address indexed beneficiary, uint256 amount);
    event ScheduleRevoked(bytes32 indexed scheduleId);

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        // Check if schedule exists
        if (vestingSchedules[vestingScheduleId].duration == 0) revert InvalidSchedule();
        //slither-disable-next-line incorrect-equality
        if (vestingSchedules[vestingScheduleId].status == Status.REVOKED) revert ScheduleWasRevoked();
        _;
    }

    /// @dev This error is fired when trying to perform an action that is not
    /// supported by the contract, like transfers and approvals. These actions
    /// will never be supported.
    error NotSupported();

    error DecimalsError();
    error InsufficientTokensInContract();
    error InsufficientReleasableTokens();
    error InvalidSchedule();
    error InvalidDuration();
    error InvalidAmount();
    error InvalidSlicePeriod();
    error InvalidStart();
    error DurationShorterThanCliff();
    error NotRevokable();
    error Unauthorized();
    error ScheduleWasRevoked();
    error TooManySchedulesForBeneficiary();

    /**
     * @notice Creates a vesting contract.
     * @param token_ address of the ERC20 native token contract
     * @param _name name of the virtual token
     * @param _symbol symbol of the virtual token
     */
    constructor(IERC20Metadata token_, string memory _name, string memory _symbol) {
        nativeToken = token_;
        if (nativeToken.decimals() != 18) revert DecimalsError();
        name = _name;
        symbol = _symbol;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ROLE_CREATE_SCHEDULE, _msgSender());
    }

    /// @dev All types of transfers are permanently disabled.
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of transfers are permanently disabled.
    function transfer(address, uint256) public pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of approvals are permanently disabled to reduce code
    /// size.
    function approve(address, uint256) public pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev Approvals cannot be set, so allowances are always zero.
    function allowance(address, address) public pure override returns (uint256) {
        return 0;
    }

    /// @notice Returns the amount of virtual tokens in existence
    function totalSupply() public view override returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /// @notice Returns the sum of virtual tokens for a user
    /// @param user The user for whom the balance is calculated
    /// @return Balance of the user
    function balanceOf(address user) public view override returns (uint256) {
        return holdersVestedAmount[user];
    }

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(address holder, uint256 index) external view returns (VestingSchedule memory) {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }

    /**
     * @notice Public function for creating a vesting schedule (only callable by contract owner)
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start start time of the vesting period
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
     * @param _revokable whether the vesting is revokable or not
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revokable,
        uint256 _amount
    ) external onlyRole(ROLE_CREATE_SCHEDULE) {
        _createVestingSchedule(_beneficiary, _start, _cliff, _duration, _slicePeriodSeconds, _revokable, _amount);
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start start time of the vesting period
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
     * @param _revokable whether the vesting is revokable or not
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function _createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revokable,
        uint256 _amount
    ) internal {
        if (getWithdrawableAmount() < _amount) revert InsufficientTokensInContract();

        // _start should be no further away than 30 weeks
        if (_start > block.timestamp + 30 weeks) revert InvalidStart();

        // _duration should be at least 7 days and max 50 years
        if (_duration < 7 days || _duration > 50 * (365 days)) revert InvalidDuration();

        if (_amount == 0) revert InvalidAmount();

        // _slicePeriodSeconds should be at least 60 seconds
        if (_slicePeriodSeconds == 0 || _slicePeriodSeconds > 60) revert InvalidSlicePeriod();

        // _duration must be longer than _cliff
        if (_duration < _cliff) revert DurationShorterThanCliff();

        if (_amount > 2 ** 200) revert InvalidAmount();
        if (holdersVestingScheduleCount[_beneficiary] >= 100) revert TooManySchedulesForBeneficiary();

        bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex(_beneficiary, holdersVestingScheduleCount[_beneficiary]);
        vestingSchedules[vestingScheduleId] =
            VestingSchedule(_start + _cliff, _start, _duration, _slicePeriodSeconds, _amount, 0, Status.INITIALIZED, _beneficiary, _revokable);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + _amount;
        vestingSchedulesIds.push(vestingScheduleId);
        ++holdersVestingScheduleCount[_beneficiary];
        holdersVestedAmount[_beneficiary] = holdersVestedAmount[_beneficiary] + _amount;
        emit ScheduleCreated(vestingScheduleId, _beneficiary, _amount, _start, _cliff, _duration, _slicePeriodSeconds, _revokable);
    }

    /**
     * @notice Revokes the vesting schedule for given identifier.
     * @param vestingScheduleId the vesting schedule identifier
     */
    function revoke(bytes32 vestingScheduleId) external onlyOwner onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        if (!vestingSchedule.revokable) revert NotRevokable();
        if (_computeReleasableAmount(vestingSchedule) > 0) {
            _release(vestingScheduleId, _computeReleasableAmount(vestingSchedule));
        }
        uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - unreleased;
        holdersVestedAmount[vestingSchedule.beneficiary] = holdersVestedAmount[vestingSchedule.beneficiary] - unreleased;
        vestingSchedule.status = Status.REVOKED;
        emit ScheduleRevoked(vestingScheduleId);
    }

    /**
     * @notice Pauses or unpauses the release of tokens and claiming of schedules
     * @param paused true if the release of tokens and claiming of schedules should be paused, false otherwise
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param amount the amount to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        if (amount > getWithdrawableAmount()) revert InsufficientTokensInContract();
        nativeToken.safeTransfer(owner(), amount);
    }

    /**
     * @notice Internal function for releasing vested amount of tokens.
     * @param vestingScheduleId the vesting schedule identifier
     * @param amount the amount to release
     */
    function _release(bytes32 vestingScheduleId, uint256 amount) internal {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        if (!isBeneficiary && !isOwner) revert Unauthorized();
        if (amount > _computeReleasableAmount(vestingSchedule)) revert InsufficientReleasableTokens();
        vestingSchedule.released = vestingSchedule.released + amount;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - amount;
        holdersVestedAmount[vestingSchedule.beneficiary] = holdersVestedAmount[vestingSchedule.beneficiary] - amount;
        emit TokensReleased(vestingScheduleId, vestingSchedule.beneficiary, amount);
        nativeToken.safeTransfer(vestingSchedule.beneficiary, amount);
    }

    /**
     * @notice Release vested amount of tokens.
     * @param vestingScheduleId the vesting schedule identifier
     * @param amount the amount to release
     */
    function release(bytes32 vestingScheduleId, uint256 amount) external nonReentrant onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        _release(vestingScheduleId, amount);
    }

    /**
     * @notice Release all available tokens for holder address
     * @param holder address of the holder & beneficiary
     */
    function releaseAvailableTokensForHolder(address holder) external nonReentrant {
        if (msg.sender != holder && msg.sender != owner()) revert Unauthorized();
        uint256 vestingScheduleCount = holdersVestingScheduleCount[holder];
        for (uint256 i = 0; i < vestingScheduleCount; i++) {
            bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex(holder, i);
            uint256 releasable = computeReleasableAmount(vestingScheduleId);
            if (releasable > 0) {
                _release(vestingScheduleId, releasable);
            }
        }
    }

    /**
     * @notice Returns the array of vesting schedule ids
     * @return vestingSchedulesIds
     */
    function getVestingSchedulesIds() external view returns (bytes32[] memory) {
        return vestingSchedulesIds;
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(bytes32 vestingScheduleId) public view onlyIfVestingScheduleNotRevoked(vestingScheduleId) returns (uint256) {
        return _computeReleasableAmount(vestingSchedules[vestingScheduleId]);
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(bytes32 vestingScheduleId) public view returns (VestingSchedule memory) {
        return vestingSchedules[vestingScheduleId];
    }

    /**
     * @notice Returns the amount of native tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return nativeToken.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @notice Computes the vesting schedule identifier for an address and an index.
     */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule storage vestingSchedule) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        //slither-disable-next-line incorrect-equality
        if (currentTime < vestingSchedule.cliff || vestingSchedule.status == Status.REVOKED) {
            return 0;
        } else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        } else {
            uint256 timeFromStart = currentTime - vestingSchedule.start;
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            // Disable warning: duration and token amounts are checked in schedule creation and prevent underflow/overflow
            //slither-disable-next-line divide-before-multiply
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            // Disable warning: duration and token amounts are checked in schedule creation and prevent underflow/overflow
            //slither-disable-next-line divide-before-multiply
            uint256 vestedAmount = vestingSchedule.amountTotal * vestedSeconds / vestingSchedule.duration;
            return vestedAmount - vestingSchedule.released;
        }
    }
}