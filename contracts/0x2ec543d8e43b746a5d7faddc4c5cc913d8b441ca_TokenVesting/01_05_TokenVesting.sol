// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenVesting
 */
contract TokenVesting is Ownable, ReentrancyGuard {
    IERC20 private immutable token;
    uint32 private immutable start;
    uint16 constant SLICE_PERIOD_DAYS = 30; // duration of a slice period for the vesting in days

    struct VestingSchedule {
        uint8 cliffDays;
        uint16 durationDays; // duration of the vesting period in days
        uint112 amountTotal; // total amount of tokens WITHOUT! amountAfterCliff to be released at the end of the vesting
        uint112 released; // amount of tokens released
        //
        uint112 amountAfterCliff;
    }

    mapping(address => VestingSchedule) private vestingSchedules;

    event Clamed(address indexed beneficiary, uint256 amount);
    event ScheduleCreated(
        address indexed beneficiary,
        uint16 durationDays,
        uint112 amount
    );
    event WithdrawedByAdmin(uint256 amount);

    /**
     * @dev Creates a vesting contract.
     * @param _token address of the ERC20 token contract
     * @param _start start timestamp of vesting
     */
    constructor(address _token, uint32 _start) {
        require(_token != address(0x0));
        token = IERC20(_token);
        start = _start;
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @dev _durationDays has 16bits long which could potentially lead to overflow.
     * However, this will only happen if specify a very large number of days, more than 49 711
     * which is more than 139 years. Vesting is designed for a maximum period of 5 years.
     * The threat of overflow is theoretical.
     * @dev It is possible to create flat sloped vesting schedules for long vesting periods with low amounts.
     * There are some border scenarios where the slope calculation outputs zero.
     * But in this vesting it is not planned to use small amounts. All phases are calculated in millions of tokens.
     * But even a single token with 8 decimals will not result in an error.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _durationDays duration in days of the period in which the tokens will vest
     * @param _cliffDays duration in days of cliff
     * @param _amountTotal total amount of tokens to be released at the end of the vesting
     * @param _amountAfterCliff amount after cliff
     */
    function createVestingSchedule(
        address _beneficiary,
        uint16 _durationDays,
        uint8 _cliffDays,
        uint112 _amountTotal,
        uint112 _amountAfterCliff
    ) external onlyOwner {
        require(
            start > uint32(block.timestamp),
            "TokenVesting: forbidden to create a schedule after the start of vesting"
        );
        require(_durationDays > 0, "TokenVesting: duration must be > 0");
        require(_amountTotal > 0, "TokenVesting: amount must be > 0");
        require(
            _durationDays >= uint16(_cliffDays),
            "TokenVesting: duration must be >= cliff"
        );
        vestingSchedules[_beneficiary] = VestingSchedule(
            _cliffDays,
            _durationDays,
            _amountTotal,
            0,
            _amountAfterCliff
        );

        token.transferFrom(
            msg.sender,
            address(this),
            _amountTotal + _amountAfterCliff
        );

        emit ScheduleCreated(
            _beneficiary,
            _durationDays,
            _amountTotal + _amountAfterCliff
        );
    }

    /**
     * @notice claim vested amount of tokens.
     */
    function claim() external nonReentrant {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        require(
            vestingSchedule.amountTotal > 0,
            "TokenVesting: only investors can claim"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount > 0, "TokenVesting: nothing to claim");

        // amountAfterCliff - could not be > vestedAmount, because it used in calculation of vestedAmount
        vestingSchedule.released += (uint112(vestedAmount) -
            vestingSchedule.amountAfterCliff);
        vestingSchedule.amountAfterCliff = 0;
        token.transfer(msg.sender, vestedAmount);

        emit Clamed(msg.sender, vestedAmount);
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(
        address _beneficiary
    ) external view returns (uint256) {
        return _computeReleasableAmount(vestingSchedules[_beneficiary]);
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(
        address _beneficiary
    ) external view returns (VestingSchedule memory) {
        return vestingSchedules[_beneficiary];
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        // If the current time is before the cliff, no tokens are releasable.
        uint32 cliffDuration = (uint32(vestingSchedule.cliffDays) * 1 days);
        if (uint32(block.timestamp) < start + cliffDuration) {
            return 0;
        }
        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        else if (
            uint32(block.timestamp) >=
            start + (uint32(vestingSchedule.durationDays) * 1 days)
        ) {
            return
                uint256(
                    vestingSchedule.amountTotal +
                        vestingSchedule.amountAfterCliff -
                        vestingSchedule.released
                );
        }
        // Otherwise, some tokens are releasable.
        else {
            uint32 vestedSlicePeriods = (uint32(block.timestamp) -
                start -
                cliffDuration) / (uint32(SLICE_PERIOD_DAYS) * 1 days); // Compute the number of full vesting periods that have elapsed.
            uint32 vestedSeconds = vestedSlicePeriods *
                (uint32(SLICE_PERIOD_DAYS) * 1 days);
            uint256 vestedAmount = (vestingSchedule.amountTotal *
                uint256(vestedSeconds)) /
                ((uint256(vestingSchedule.durationDays) -
                    uint256(vestingSchedule.cliffDays)) * 1 days); // Compute the amount of tokens that are vested.
            return
                vestedAmount +
                uint256(vestingSchedule.amountAfterCliff) -
                uint256(vestingSchedule.released); // Subtract the amount already released and return.
        }
    }
}