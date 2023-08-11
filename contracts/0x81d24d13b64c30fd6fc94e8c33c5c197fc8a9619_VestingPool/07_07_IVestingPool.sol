// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 * @title Vesting Pool Interface
 * @dev Interface for a vesting pool with common functionalities.
 */

interface IVestingPool {
    /**
     * @dev AddressCannotBeZero - Error thrown when the provided address is zero.
     */
    error AddressCannotBeZero();
    /**
     * @dev DurationMustBeGreaterThanZero - Error thrown when the duration of the vesting schedule is set to zero.
     */
    error DurationMustBeGreaterThanZero();
    /**
     * @dev AmountMustBeGreaterThanZero - Error thrown when the amount of tokens for vesting is set to zero.
     */
    error AmountMustBeGreaterThanZero();
    /**
     *  @dev DurationMustBeGreaterThanCliff - Error thrown when the duration of the vesting schedule is less than or
     * equal to the cliff period.
     */
    error DurationMustBeGreaterThanCliff();
    /**
     * @dev VestingNotRevocable - Error thrown when attempting to revoke a non-revocable vesting schedule.
     */
    error VestingNotRevocable();
    /**
     * @dev NotEnoughWithdrawableFunds - Error thrown when attempting to withdraw more funds than available.
     */

    error NotEnoughWithdrawableFunds();

    /**
     * @dev BeneficiaryDoesNotExists - Error thrown when the beneficiary does not exist.
     */
    error BeneficiaryDoesNotExists();

    /**
     * @dev IndexOutOfBound - Error thrown when attempting to access an index that is out of bounds.
     */

    error IndexOutOfBound();

    /**
     * @dev OnlyBeneficiaryAndOwnerCanReleaseVestedTokens - Error thrown when a non-beneficiary or non-owner attempts to
     * release vested tokens.
     */
    error OnlyBeneficiaryAndOwnerCanReleaseVestedTokens();

    /**
     * @dev NotEnoughVestedTokens - Error thrown when there are not enough vested tokens to release.
     */
    error NotEnoughVestedTokens();

    /**
     * @dev NotInitialized - Error thrown when a vesting schedule is not initialized.
     */
    error NotInitialized();

    /**
     * @dev AlreadyRevoked - Error thrown when a vesting schedule has already been revoked.
     */
    error AlreadyRevoked();

    /**
     * @dev InsufficientUpdatedAmount - Error thrown when a wrong inputs are entered.
     */
    error InsufficientUpdatedAmount();

    /**
     *  @dev VestingSchedule - Struct representing a vesting schedule.
     *  @param initialized: Indicates if the vesting schedule is initialized.
     *  @param beneficiary: The beneficiary of the tokens after they are released.
     *  @param cliff: The cliff period in seconds.
     *  @param start: The start time of the vesting period.
     *  @param duration: The duration of the vesting period in seconds.
     *  @param revocable: Indicates if the vesting schedule is revocable.
     *  @param amountTotal: The total amount of tokens to be released at the end of the vesting.
     *  @param released: The amount of tokens already released.
     *  @param revoked: Indicates if the vesting schedule has been revoked.
     */

    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        bool revocable;
        uint256 amountTotal;
        uint256 released;
        bool revoked;
    }

    /**
     * @dev Struct containing information about the vesting pool.
     * @param poolShare The percentage share of the vesting pool.
     * @param distributer The address of the token distributer.
     * @param tokenAmount The total amount of tokens in the vesting pool.
     * @param poolName The name of the vesting pool.
     */

    struct PoolInfo {
        uint256 poolShare;
        address distributer;
        uint256 tokenAmount;
        string poolName;
    }
    /**
     *    @dev Created - Emitted when a new vesting schedule is created.
     * @param beneficiary: The beneficiary of the tokens after they are released.
     * @param amountTotal: The total amount of tokens to be released at the end of the vesting.
     */

    event Created(address indexed beneficiary, uint256 amountTotal);
    /**
     * @dev Released - Emitted when vested tokens are released
     *   @param beneficiary: The beneficiary of the released tokens.
     *   @param amount: The amount of tokens released.
     */
    event Released(address indexed beneficiary, uint256 amount);

    /**
     * @dev BeneficiaryUpdated - Emitted when beneficiary is updated
     *   @param previousBeneficiary: previous address of beneficiary.
     *   @param newBeneficiary: new address of beneficiary.
     */
    event BeneficiaryUpdated(address previousBeneficiary, address newBeneficiary);

    /**
     * @dev BeneficiaryAmountUpdated - Emitted when beneficiary tokens are updated
     *   @param previousAmount: Previous amounts of beneficiary.
     *   @param newAmount: New amount of beneficiary.
     */
    event BeneficiaryAmountUpdated(uint256 previousAmount, uint256 newAmount);
}