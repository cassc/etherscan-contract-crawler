// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface ILockedRevenueDistributionToken {
    /**
     * @notice        Represents a withdrawal request, packed into a single word.
     * @custom:member unlockedAt Timestamp after which the withdrawal is unlocked.
     * @custom:member shares     Amount of shares to be burned upon withdrawal execution.
     * @custom:member assets     Amount of assets to be returned to user upon withdrawal execution.
     */
    struct WithdrawalRequest {
        uint32 unlockedAt;
        uint32 lockTime;
        uint96 shares;
        uint96 assets;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                              Events                               ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Emitted when burning shares upon withdrawal request cancellation.
     * @param  assets_ Amount of assets returned to contract address.
     * @param  shares_ Share delta between withdrawal request creation and cancellation.
     */
    event CancellationBurn(uint256 assets_, uint256 shares_);

    /**
     * @notice Emitted when the instant withdrawal fee is set.
     * @param  percentage_ A percentage value from 0 to 100.
     */
    event InstantWithdrawalFeeChanged(uint256 percentage_);

    /**
     * @notice Emitted when time-to-unlock for a standard withdrawal set.
     * @param  lockTime_ Integer length of lock time, e.g. `26 weeks`.
     */
    event LockTimeChanged(uint256 lockTime_);

    /**
     * @notice Emitted when redistributing rewards upon early execution or cancellation of a withdrawal request.
     * @param  assets_ Assets redistributed to remaining stakers.
     */
    event Redistribute(uint256 assets_);

    /**
     * @notice Emitted when refunding shares upon withdrawal request cancellation.
     * @param  receiver_   Account to refund shares to at spot rate.
     * @param  assets_     Equivalent asset value for shares returned.
     * @param  shares_     Amount of shares returned to the receiver.
     */
    event Refund(address indexed receiver_, uint256 assets_, uint256 shares_);

    /**
     * @notice Emitted when fee exemption status has been set for an address.
     * @param  account_ Address in which to apply the exemption.
     * @param  status_  True for exempt, false to remove exemption.
     */
    event WithdrawalFeeExemptionStatusChanged(address indexed account_, bool status_);

    /**
     * @notice Emitted when an instant withdrawal fee is paid.
     * @param  caller_   The caller of the `redeem` or `withdraw` function.
     * @param  receiver_ The receiver of the assets.
     * @param  owner_    The owner of the shares or withdrawal request.
     * @param  fee_      The assets paid as fee.
     */
    event WithdrawalFeePaid(address indexed caller_, address indexed receiver_, address indexed owner_, uint256 fee_);

    /**
     * @notice Emitted when a new withdrawal request has been created for an account.
     * @param  request_ Struct containing shares, assets, and maturity date of the created request.
     * @param  pos_   Index/position of the withdrawal request created.
     */
    event WithdrawalRequestCreated(WithdrawalRequest request_, uint256 pos_);

    /**
     * @notice Emitted when an account cancels any existing withdrawal requests.
     * @param  pos_   Index/position of the withdrawal request cancelled.
     */
    event WithdrawalRequestCancelled(uint256 pos_);

    /**
     * @notice Emitted when a withdrawal request has been executed with shares burned and assets withdrawn.
     * @param  pos_ Index/position of the withdrawal request executed.
     */
    event WithdrawalRequestExecuted(uint256 pos_);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          State Variables                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Constant maximum lock time able to be set using `setLockTime` to avoid permanent lockup.
     * @return maximumLockTime_ Maxmimum lock time integer length, e.g. `104 weeks`.
     */
    function MAXIMUM_LOCK_TIME() external view returns (uint256 maximumLockTime_);

    /**
     * @notice Constant vesting period, used in `updateVestingSchedule`.
     * @return vestingPeriod_ Fixed vesting period, e.g. `2 weeks`.
     */
    function VESTING_PERIOD() external view returns (uint256 vestingPeriod_);

    /**
     * @notice Constant time window in which unlocked withdrawal requests can be executed.
     * @return withdrawalWindow_ Fixed withdrawal window, e.g. `4 weeks`.
     */
    function WITHDRAWAL_WINDOW() external view returns (uint256 withdrawalWindow_);

    /**
     * @notice Percentage withdrawal fee to be applied to instant withdrawals.
     * @return instantWithdrawalFee_ A percentage value from 0 to 100.
     */
    function instantWithdrawalFee() external view returns (uint256 instantWithdrawalFee_);

    /**
     * @notice The lock time set for standard withdrawals to become unlocked.
     * @return lockTime_ Length of lock of a standard withdrawal request, e.g. `26 weeks`.
     */
    function lockTime() external view returns (uint256 lockTime_);

    /**
     * @notice Returns exemption status for a given account. When true then instant withdrawal fee will not apply.
     * @param  account_ Account to check for exemption.
     * @return status_  Exemption status.
     */
    function withdrawalFeeExemptions(address account_) external view returns (bool status_);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                     Administrative Functions                      ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Sets the intstant withdrawal fee, applied when making instant withdrawals or redemptions.
     * @notice Can only be set by owner.
     * @param  percentage_ Fee percentage. Must be an integer between 0 and 100 inclusive.
     */
    function setInstantWithdrawalFee(uint256 percentage_) external;

    /**
     * @notice Sets the lock time for standard withdrawals to become unlocked.
     * @notice Can only be set by owner.
     * @notice Must be lower than MAXIMUM_LOCK_TIME to prevent permanent lockup.
     * @param  lockTime_ Length of lock of a standard withdrawal request.
     */
    function setLockTime(uint256 lockTime_) external;

    /**
     * @notice Sets or unsets an owner address to be exempt from the withdrawal fee.
     * @notice Useful in case of future migrations where an approved contract may be given permission to migrate
     * balances to a new token. Can also be used to exempt third-party vaults from facing withdrawal fee when
     * managing balances, such as lending platform liquidations.
     * @notice Can only be set by contract `owner`.
     * @dev    The zero address cannot be set as exmempt as this will always represent an address that pays fees.
     * @param  owner_  Owner address to exempt from instant withdrawal fees.
     * @param  status_ true to add exemption, false to remove exemption.
     */
    function setWithdrawalFeeExemption(address owner_, bool status_) external;

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Creates a new withdrawal request for future execution using the shares conversion at the point of
     * request. May only be executed after the unlock date.
     * @notice Transfers shares to the vault contract to reserve them, reducing share balance.
     * @param  shares_ Amount of shares to redeem upon unlock.
     */
    function createWithdrawalRequest(uint256 shares_) external;

    /**
     * @notice Removes an open withdrawal request for the sender.
     * @param  pos_ Index/position of the withdrawal request to be cancelled.
     */
    function cancelWithdrawalRequest(uint256 pos_) external;

    /**
     * @notice Executes an existing withdrawal request for msg.sender. Before the request is unlocked, a percentage
     * fee will be paid, equal to a percentage of the instantWithdrawalFee by time elapsed of the request.
     * @param  pos_ Index/position of the withdrawal request to be executed.
     */
    function executeWithdrawalRequest(uint256 pos_) external;

    /**
     * @notice Executes an existing withdrawal request that has passed its unlock date.
     * @dev    Identical to parent implementation but made public by fixed vesting period and removal of owner check.
     * @return issuanceRate_ Slope of release of newly added assets, scaled up by `precision`.
     * @return freeAssets_   Amount of assets currently released to stakers.
     */
    function updateVestingSchedule() external returns (uint256 issuanceRate_, uint256 freeAssets_);

    /**
     * @notice ERC5143 slippage-protected deposit method. The transaction will revert if the shares to be returned is
     * less than minShares_.
     * @param  assets_    Amount of assets to deposit.
     * @param  receiver_  The receiver of the shares.
     * @param  minShares_ Minimum amount of shares to be returned.
     * @return shares_    Amount of shares returned to receiver_.
     */
    function deposit(uint256 assets_, address receiver_, uint256 minShares_) external returns (uint256 shares_);

    /**
     * @notice ERC5143 slippage-protected mint method. The transaction will revert if the assets to be deducted is
     * greater than maxAssets_.
     * @param  shares_    Amount of shares to mint.
     * @param  receiver_  The receiver of the shares.
     * @param  maxAssets_ Maximum amount of assets to be deducted.
     * @return assets_    Amount of deducted when minting shares.
     */
    function mint(uint256 shares_, address receiver_, uint256 maxAssets_) external returns (uint256 assets_);

    /**
     * @notice ERC5143 slippage-protected redeem method. The transaction will revert if the assets to be returned is
     * less than minAssets_.
     * @param  shares_    Amount of shares to redeem.
     * @param  receiver_  The receiver of the assets.
     * @param  owner_     Owner of shares making redemption.
     * @param  minAssets_ Minimum amount of assets to be returned.
     * @return assets_    Amount of assets returned.
     */
    function redeem(uint256 shares_, address receiver_, address owner_, uint256 minAssets_)
        external
        returns (uint256 assets_);

    /**
     * @notice ERC5143 slippage-protected withdraw method. The transaction will revert if the shares to be deducted is
     * greater than maxShares_.
     * @param  assets_    Amount of assets to withdraw.
     * @param  receiver_  The receiver of the assets.
     * @param  owner_     Owner of shares making withdrawal.
     * @param  maxShares_ Minimum amount of shares to be deducted.
     * @return shares_    Amount of shares deducted.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_, uint256 maxShares_)
        external
        returns (uint256 shares_);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          View Functions                           ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Previews a redemption of shares for owner. Applies withdrawal fee if owner does not have an exemption.
     * @param  owner_  Owner of shares making redemption.
     * @param  shares_ Amount of shares to redeem.
     * @return assets_ Assets redeemed for shares for owner.
     * @param  fee_    The assets paid as fee.
     */
    function previewRedeem(uint256 shares_, address owner_) external view returns (uint256 assets_, uint256 fee_);

    /**
     * @notice Previews a withdrawal of assets for owner. Applies withdrawal fee if owner does not have an exemption.
     * @param  owner_  Owner of shares makeing withdrawal.
     * @param  assets_ Amount of assets to withdraw.
     * @return shares_ Shares needed to be burned for owner.
     * @param  fee_    The assets paid as fee.
     */
    function previewWithdraw(uint256 assets_, address owner_) external view returns (uint256 shares_, uint256 fee_);

    /**
     * @notice Previews a withdrawal request execution, calculating the assets returned to the receiver and fee paid.
     * @notice Fee percentage reduces linearly from instantWithdrawalFee until 0 at the unlockedAt timestamp.
     * @param  pos_     Index/position of the withdrawal request to be previewed.
     * @param  owner_   Owner of the withdrawal request.
     * @return request_ The WithdrawalRequest struct within storage.
     * @return assets_  Amount of assets returned to owner if withdrawn.
     * @return fee_     The assets paid as fee.
     */
    function previewWithdrawalRequest(uint256 pos_, address owner_)
        external
        view
        returns (WithdrawalRequest memory request_, uint256 assets_, uint256 fee_);

    /**
     * @notice Returns a count of the number of created withdrawal requests for an account, including cancelled.
     * @param  owner_ Account address of owner of withdrawal requests.
     * @return count_ Number of withdrawal request created for owner account.
     */
    function withdrawalRequestCount(address owner_) external view returns (uint256 count_);

    /**
     * @notice Returns an array of created withdrawal requests for an account, including cancelled.
     * @param  owner_    Account address of owner of withdrawal requests.
     * @return requests_ Array of withdrawal request structs for an owner.
     */
    function withdrawalRequests(address owner_) external view returns (WithdrawalRequest[] memory requests_);

    /**
     * @notice Returns existing withdrawal request for a given account.
     * @param  account_ Account address holding withdrawal request.
     * @param  pos_     Index/position of the withdrawal request in the array.
     * @return request_ Withdrawal request struct found at position for owner.
     */
    function withdrawalRequests(address account_, uint256 pos_)
        external
        view
        returns (WithdrawalRequest memory request_);
}