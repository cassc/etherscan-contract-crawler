// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 * @title VestingPool
 * @dev A contract that manages token vesting schedules for beneficiaries.
 * It allows an owner to create and manage multiple vesting schedules for different beneficiaries.
 * The vesting schedules can be revocable or non-revocable based on the provided configuration.
 * This contract is compatible with ERC20 tokens.
 */
import "./VestingFactory.sol";
import "./interface/IVestingPool.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract VestingPool is IVestingPool, Ownable {
    /**
     * @dev Address of the token for vesting.
     */
    address public constant token = 0x37C997B35C619C21323F3518B9357914E8B99525;
    /**
     * @dev Private variable to store ERC20 token interface
     */
    IERC20 private _token;
    /**
     * @dev Private variable to store total amount of vested tokens
     */
    uint256 private _vestingSchedulesTotalAmount;
    /**
     * @dev Public variable to store total supply
     */
    uint256 public totalSupply;
    /**
     * @dev Public variable to store total released tokens over the time
     */
    uint256 public totalReleased;
    /**
     * @dev Private variable to store an array of vesting schedule beneficiaries
     */
    address[] private _vestingSchedulesBeneficiaries;
    /**
     * @dev Mapping to store vesting schedule information for each beneficiary
     */
    mapping(address => VestingSchedule) private _vestingSchedules;
    /**
     * @dev Mapping to store vesting count for each holder
     */
    mapping(address => uint256) private _holdersVestingCount;
    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */

    modifier onlyIfVestingScheduleNotRevoked(address beneficiary) {
        if (_vestingSchedules[beneficiary].initialized == false) revert NotInitialized();
        if (_vestingSchedules[beneficiary].revoked == true) revert AlreadyRevoked();
        _;
    }
    /**
     * @dev Initializes the vesting pool with the provided parameters.
     * @param poolOwner The owner of the vesting pool.
     */

    constructor(address poolOwner) {
        transferOwnership(poolOwner);
        _token = IERC20(token);
    }
    /**
     * @dev Fallback function is executed if none of the other functions match the function
     * identifier or no data was provided with the function call.
     */

    fallback() external { }
    /**
     * @notice Creates a vesting schedule for a beneficiary.
     * @param beneficiary The address of the beneficiary.
     * @param start The start time of the vesting schedule.
     * @param cliff The duration of the cliff in seconds.
     * @param duration The total duration of the vesting schedule in seconds.
     * @param revocable A boolean indicating if the vesting schedule can be revoked.
     * @param amount The total amount of tokens in the vesting schedule.
     */

    function createVestingSchedule(
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        bool revocable,
        uint256 amount
    )
        external
        onlyOwner
    {
        if (beneficiary == address(0)) {
            revert AddressCannotBeZero();
        }
        if (duration == 0) revert DurationMustBeGreaterThanZero();
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (duration <= cliff) revert DurationMustBeGreaterThanCliff();
        uint256 cliffFromStart = start + cliff;
        _vestingSchedules[beneficiary] =
            VestingSchedule(true, beneficiary, cliffFromStart, start, duration, revocable, amount, 0, false);
        _vestingSchedulesTotalAmount = _vestingSchedulesTotalAmount + amount;
        totalSupply = totalSupply + amount;
        _vestingSchedulesBeneficiaries.push(beneficiary);
        emit Created(beneficiary, amount);
    }
    /**
     * @notice Updates the beneficiary address of a vesting schedule.
     * @param previousBeneficiary The address of the previous beneficiary.
     * @param newBeneficiary The address of the new beneficiary.
     */

    function updateBeneficiary(
        address previousBeneficiary,
        address newBeneficiary
    )
        external
        onlyIfVestingScheduleNotRevoked(previousBeneficiary)
        onlyOwner
    {
        if (newBeneficiary == address(0)) {
            revert AddressCannotBeZero();
        }
        VestingSchedule storage vestingSchedule = _vestingSchedules[previousBeneficiary];
        uint256 releasedAmount = vestingSchedule.released;
        uint256 amountTotal = vestingSchedule.amountTotal;
        bool revocable = vestingSchedule.revocable;
        uint256 start = vestingSchedule.start;
        uint256 cliff = vestingSchedule.cliff;
        uint256 duration = vestingSchedule.duration;
        _vestingSchedules[newBeneficiary] =
            VestingSchedule(true, newBeneficiary, cliff, start, duration, revocable, amountTotal, releasedAmount, false);
        delete _vestingSchedules[previousBeneficiary];
        emit BeneficiaryUpdated(previousBeneficiary, newBeneficiary);
    }

    /**
     * @notice Updates the beneficiary amount for vesting schedule.
     * @param beneficiary The address of the beneficiary.
     * @param amount The updated amount for the beneficiary.
     * * @param increase boolean check to increase the amount or decrease.
     */

    function updateBeneficiaryAmount(
        address beneficiary,
        uint256 amount,
        bool increase
    )
        external
        onlyIfVestingScheduleNotRevoked(beneficiary)
        onlyOwner
    {
        VestingSchedule storage vestingSchedule = _vestingSchedules[beneficiary];
        uint256 previousAmount = vestingSchedule.amountTotal;

        uint256 updatedAmount = increase ? previousAmount + amount : previousAmount - amount;

        if (updatedAmount < vestingSchedule.released) {
            revert InsufficientUpdatedAmount();
        }

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            _release(beneficiary);
        }

        vestingSchedule.amountTotal = updatedAmount;
        if (increase) {
            totalSupply += amount;
        }
        emit BeneficiaryAmountUpdated(previousAmount, updatedAmount);
    }

    /**
     * @notice Revokes a vesting schedule for a beneficiary.
     * @param beneficiary The address of the beneficiary.
     */

    function revoke(address beneficiary) external onlyOwner onlyIfVestingScheduleNotRevoked(beneficiary) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[beneficiary];
        if (vestingSchedule.revocable == false) revert VestingNotRevocable();
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            _release(beneficiary);
        }
        uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
        _vestingSchedulesTotalAmount = _vestingSchedulesTotalAmount - unreleased;
        vestingSchedule.revoked = true;
        if (unreleased > 0) {
            _token.transfer(owner(), unreleased);
        }
    }
    /**
     * @notice Withdraws a specified amount of tokens from the vesting pool.
     * @param amount The amount of tokens to be withdrawn.
     */

    function withdraw(uint256 amount, address recipient) external onlyOwner {
        if (amount > getWithdrawableAmount()) revert NotEnoughWithdrawableFunds();
        _token.transfer(recipient, amount);
    }
    /**
     * @notice Releases the vested tokens for a beneficiary.
     * @param beneficiary The address of the beneficiary.
     */

    function release(address beneficiary) external onlyIfVestingScheduleNotRevoked(beneficiary) {
        _release(beneficiary);
    }
    /**
     * @notice Recovers ERC20 tokens sent to the contract by mistake.
     * @param tokenAddress The address of the ERC20 token.
     * @param tokenAmount The amount of tokens to be recovered.
     */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

    /**
     * @notice Returns the vesting schedule of a beneficiary.
     * @param beneficiary The address of the beneficiary.
     * @return The vesting schedule struct.
     */

    function getVestingSchedule(address beneficiary) external view returns (VestingSchedule memory) {
        if (_vestingSchedules[beneficiary].initialized) {
            return _vestingSchedules[beneficiary];
        } else {
            revert BeneficiaryDoesNotExists();
        }
    }
    /**
     * @notice Returns the total amount of tokens in all vesting schedules.
     * @return The total amount of tokens.
     */

    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return _vestingSchedulesTotalAmount;
    }
    /**
     * @notice Computes the releasable amount of tokens for a beneficiary.
     * @param beneficiary The address of the beneficiary.
     * @return The releasable amount of tokens.
     */

    function computeReleasableAmount(address beneficiary)
        external
        view
        onlyIfVestingScheduleNotRevoked(beneficiary)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = _vestingSchedules[beneficiary];
        return _computeReleasableAmount(vestingSchedule);
    }
    /**
     * @notice Computes the total amount of tokens in contract.
     * @return The total amount of tokens.
     */

    function balanceOf() external view returns (uint256) {
        return _balanceOf();
    }

    /**
     * @notice Calculates the amount of tokens that can be withdrawn by the owner.
     * @return The amount of tokens that can be withdrawn.
     */

    function getWithdrawableAmount() public view returns (uint256) {
        if (_balanceOf() > _vestingSchedulesTotalAmount) {
            return _balanceOf() - _vestingSchedulesTotalAmount;
        } else {
            return 0;
        }
    }
    /**
     * @notice Returns the total number of vesting schedules managed by this contract.
     * @return The number of vesting schedules.
     */

    function getVestingSchedulesCount() public view returns (uint256) {
        return _vestingSchedulesBeneficiaries.length;
    }
    /**
     * @dev Releases the vested amount of tokens for the specified beneficiary.
     * @param beneficiary The address of the beneficiary whose tokens will be released.
     */

    function _release(address beneficiary) private onlyIfVestingScheduleNotRevoked(beneficiary) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[beneficiary];
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        uint256 releasedAmount = vestingSchedule.released;
        if (vestedAmount > 0) {
            vestingSchedule.released = releasedAmount + vestedAmount;
            totalReleased = totalReleased + vestedAmount;
            _vestingSchedulesTotalAmount -= vestedAmount;
            _token.transfer(beneficiary, vestedAmount);
            emit Released(beneficiary, vestedAmount);
        }
    }
    /**
     * @dev Calculates the releasable amount of tokens for a given vesting schedule.
     * @param vestingSchedule The vesting schedule to compute the releasable amount for.
     * @return The amount of releasable tokens.
     */

    function _computeReleasableAmount(VestingSchedule memory vestingSchedule) private view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked) {
            return 0;
        } else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        } else {
            uint256 timeFromStart = currentTime - vestingSchedule.start;
            uint256 vestedAmount = (vestingSchedule.amountTotal / vestingSchedule.duration) * timeFromStart;
            return vestedAmount - vestingSchedule.released;
        }
    }
    /**
     * @dev Retrieves the contract balance of the vested token.
     * @return The current balance of vested tokens.
     */

    function _balanceOf() private view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}