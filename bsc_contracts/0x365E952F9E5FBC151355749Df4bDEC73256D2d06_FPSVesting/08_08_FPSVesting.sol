// SPDX-License-Identifier: Apache-2.0
// The below is a modified version of the original open-source code found under
// https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol
// released under the Apache-2.0 license
// Original license: https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FPSVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct VestingSchedule {
        bool initialized;
        // beneficiary of tokens after they are released
        address  beneficiary;
        // cliff period in seconds
        uint256  cliff;
        // start time of the vesting period
        uint256  start;
        // duration of the vesting period in seconds
        uint256  duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool  revocable;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256  released;
        // whether or not the vesting has been revoked
        bool revoked;
    }

    // address of the FPS ERC20 token
    IERC20 immutable private _token;

    bytes32[] private _vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private _vestingSchedules;
    uint256 private _vestingSchedulesTotalAmount;
    mapping(address => uint256) private _holdersVestingCount;

    event Released(bytes32 vestingScheduleId, uint256 amount);
    event Revoked(bytes32 vestingScheduleId);

    /**
    * @dev Reverts if the vesting schedule does not exist or has been revoked.
    */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(_vestingSchedules[vestingScheduleId].initialized);
        require(!_vestingSchedules[vestingScheduleId].revoked);
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the FPS ERC20 token contract
     */
    constructor(address token_) {
        require(token_ != address(0x0));
        _token = IERC20(token_);
    }

    /**
    * @dev Returns the number of vesting schedules associated to a beneficiary.
    * @return the number of vesting schedules
    */
    function getVestingSchedulesCountByBeneficiary(address beneficiary)
    external
    view
    returns(uint256) {
        return _holdersVestingCount[beneficiary];
    }

    /**
    * @dev Returns the vesting schedule id at the given index.
    * @return the vesting id
    */
    function getVestingIdAtIndex(uint256 index)
    external
    view
    returns(bytes32) {
        require(index < getVestingSchedulesCount(), "FPSVesting: index out of bounds");
        return _vestingSchedulesIds[index];
    }

    /**
    * @notice Returns the vesting schedule information for a given holder and index.
    * @return the vesting schedule structure information
    */
    function getVestingScheduleByAddressAndIndex(address holder, uint256 index)
    external
    view
    returns(VestingSchedule memory) {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }


    /**
    * @notice Returns the total amount of vested funds.
    * @return the total amount of vested funds
    */
    function getVestingSchedulesTotalAmount()
    external
    view
    returns(uint256) {
        return _vestingSchedulesTotalAmount;
    }

    /**
    * @dev Returns the address of the FPS ERC20 token managed by the vesting contract.
    */
    function getToken()
    external
    view
    returns(address) {
        return address(_token);
    }

    /**
    * @notice Creates a new vesting schedule for a beneficiary.
    * @param beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param start start time of the vesting period
    * @param cliffDelta duration in seconds of the cliff in which tokens will begin to vest
    * @param duration duration in seconds of the period in which the tokens will vest
    * @param slicePeriodSeconds duration of a slice period for the vesting in seconds
    * @param revocable whether the vesting is revocable or not
    * @param amount total amount of tokens to be released at the end of the vesting
    */
    function createVestingSchedule(
        address beneficiary,
        uint256 start,
        uint256 cliffDelta,
        uint256 duration,
        uint256 slicePeriodSeconds,
        bool revocable,
        uint256 amount
    )
    public
    onlyOwner {
        require(
            getWithdrawableAmount() >= amount,
            "FPSVesting: cannot create vesting schedule because not sufficient tokens"
        );
        require(duration > 0, "FPSVesting: duration must be > 0");
        require(amount > 0, "FPSVesting: amount must be > 0");
        require(slicePeriodSeconds >= 1, "FPSVesting: slicePeriodSeconds must be >= 1");
        require(cliffDelta <= duration, "FPSVesting: cliffDelta cannot be higher than duration");
        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(beneficiary);
        uint256 cliff = start + cliffDelta;
        _vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            beneficiary,
            cliff,
            start,
            duration,
            slicePeriodSeconds,
            revocable,
            amount,
            0,
            false
        );
        _vestingSchedulesTotalAmount += amount;
        _vestingSchedulesIds.push(vestingScheduleId);
        _holdersVestingCount[beneficiary] += 1;
    }

    /**
    * @notice Revokes the vesting schedule for given identifier.
    * @param vestingScheduleId the vesting schedule identifier
    */
    function revoke(bytes32 vestingScheduleId)
    public
    onlyOwner
    onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[vestingScheduleId];
        require(vestingSchedule.revocable, "FPSVesting: vesting is not revocable");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            release(vestingScheduleId, vestedAmount);
        }
        uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
        _vestingSchedulesTotalAmount -= unreleased;
        vestingSchedule.revoked = true;
        emit Revoked(vestingScheduleId);
    }

    /**
    * @notice Withdraw the specified amount if possible.
    * @param amount the amount to withdraw
    */
    function withdraw(uint256 amount)
    public
    nonReentrant
    onlyOwner {
        require(getWithdrawableAmount() >= amount, "FPSVesting: not enough withdrawable funds");
        _token.safeTransfer(owner(), amount);
    }

    /**
    * @notice Release vested amount of tokens.
    * @param vestingScheduleId the vesting schedule identifier
    * @param amount the amount to release
    */
    function release(
        bytes32 vestingScheduleId,
        uint256 amount
    )
    public
    nonReentrant
    onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "FPSVesting: only beneficiary and owner can release vested tokens"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "FPSVesting: cannot release tokens, not enough vested tokens");
        vestingSchedule.released += amount;
        _vestingSchedulesTotalAmount -= amount;
        _token.safeTransfer(vestingSchedule.beneficiary, amount);
        emit Released(vestingScheduleId, amount);
    }

    /**
    * @dev Returns the number of vesting schedules managed by this contract.
    * @return the number of vesting schedules
    */
    function getVestingSchedulesCount()
    public
    view
    returns(uint256) {
        return _vestingSchedulesIds.length;
    }

    /**
    * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
    * @return the vested amount
    */
    function computeReleasableAmount(bytes32 vestingScheduleId)
    public
    onlyIfVestingScheduleNotRevoked(vestingScheduleId)
    view
    returns(uint256) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
    * @notice Returns the vesting schedule information for a given identifier.
    * @return the vesting schedule structure information
    */
    function getVestingSchedule(bytes32 vestingScheduleId)
    public
    view
    returns(VestingSchedule memory) {
        return _vestingSchedules[vestingScheduleId];
    }

    /**
    * @dev Returns the amount of tokens that can be withdrawn by the owner.
    * @return the amount of tokens
    */
    function getWithdrawableAmount()
    public
    view
    returns(uint256) {
        return _token.balanceOf(address(this)) - _vestingSchedulesTotalAmount;
    }

    /**
    * @dev Computes the next vesting schedule identifier for a given holder address.
    */
    function computeNextVestingScheduleIdForHolder(address holder)
    public
    view
    returns(bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(holder, _holdersVestingCount[holder]);
    }

    /**
    * @dev Computes the vesting schedule identifier for an address and an index.
    */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index)
    public
    pure
    returns(bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
    * @dev Computes the releasable amount of tokens for a vesting schedule.
    * @return the amount of releasable tokens
    */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
    internal
    view
    returns(uint256) {
        uint256 currentTime = getCurrentTime();
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked) {
            return 0;
        } else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        } else {
            uint256 timeFromStart = currentTime - vestingSchedule.start;
            uint secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            uint256 vestedAmount = vestingSchedule.amountTotal * vestedSeconds / vestingSchedule.duration;
            return vestedAmount - vestingSchedule.released;
        }
    }

    function getCurrentTime()
    internal
    virtual
    view
    returns(uint256) {
        return block.timestamp;
    }
}