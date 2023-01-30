// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title KunciVesting
 */
contract KunciVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    struct VestingSchedule {
        bool initialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // start time of the vesting period
        uint256 start;
        // duration of locking before vesting start releasing
        uint256 lockDuration;
        // duration of the vesting period in seconds
        uint256 duration;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens release d
        uint256 released;
    }

    // address of the ERC20 token
    IERC20 private immutable _token;
    
    VestingSchedule[] public vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => VestingSchedule) private holderVestingSchedules;

    event Released(address indexed beneficiary, uint256 amount);
    event VestingScheduleStarted(address indexed beneficiary, uint256 start, uint256 lockDuration, uint256 duration, uint256 amount);

    /**
     * @dev Reverts if no vesting schedule matches the passed identifier.
     */
    modifier onlyIfVestingScheduleNotExists(address userAdddress) {
        require(holderVestingSchedules[userAdddress].initialized == false, "User already in vesting");
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     */
    constructor(IERC20 token_) {
        require(address(token_) != address(0x0), "token must be non-zero address");
        _token = token_;
    }

    /**
     * @dev Returns vesting schedule associated to a beneficiary.
     * @return vesting schedule
     */
    function getVestingSchedulesByBeneficiary(address _beneficiary)
        external
        view
        returns (VestingSchedule memory)
    {
        return holderVestingSchedules[_beneficiary];
    }

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getToken() external view returns (address) {
        return address(_token);
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start start time of the vesting period
     * @param _lockDuration duration in seconds of locking before vesting start releasing
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _lockDuration,
        uint256 _duration,
        uint256 _amount
    ) public onlyOwner onlyIfVestingScheduleNotExists(_beneficiary) {
        require(_lockDuration >= 0, "TokenVesting: duration must be >= 0");
        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(_token.allowance(msg.sender, address(this)) >= _amount, "Token allowance is insufficient");
        holderVestingSchedules[_beneficiary] = VestingSchedule(
            true,
            _beneficiary,
            _start,
            _lockDuration,
            _duration,
            _amount,
            0
        );
        vestingSchedules.push(holderVestingSchedules[_beneficiary]);

        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + _amount;

        _token.safeTransferFrom(msg.sender, address(this), _amount);

        emit VestingScheduleStarted(_beneficiary, _start, _lockDuration, _duration, _amount);
    }

    /**
     * @notice Release vested amount of tokens.
     * @param _beneficiary vesting schedule beneficiary address
     * @param amount the amount to release
     */
    function release(address _beneficiary, uint256 amount)
        public
        nonReentrant
    {
        VestingSchedule storage vestingSchedule = holderVestingSchedules[_beneficiary];
        uint256 vestedAmount = computeReleasableAmount(_beneficiary);
        uint256 currentTime = getCurrentTime();

        require(amount > 0, "Amount incorrect");
        require(vestedAmount >= amount, "Not enough vested tokens");
        require(currentTime >= vestingSchedule.start + vestingSchedule.lockDuration, "Lock duration is not ended");

        vestingSchedule.released = vestingSchedule.released + amount;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - amount;
        _token.safeTransfer(vestingSchedule.beneficiary, amount);

        emit Released(vestingSchedule.beneficiary, amount);
    }

    /**
     * @dev Returns the number of vesting schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedules.length;
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(address _beneficiary)
        public
        view
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = holderVestingSchedules[_beneficiary];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        uint256 timeSinceUnlocked = currentTime - (vestingSchedule.start + vestingSchedule.lockDuration);
        if (timeSinceUnlocked > vestingSchedule.duration) {
            timeSinceUnlocked = vestingSchedule.duration;
        }
        uint256 unlockedAmount = vestingSchedule.amountTotal * timeSinceUnlocked / vestingSchedule.duration;
        uint256 eligibleAmount = unlockedAmount - vestingSchedule.released;
        return eligibleAmount;
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}