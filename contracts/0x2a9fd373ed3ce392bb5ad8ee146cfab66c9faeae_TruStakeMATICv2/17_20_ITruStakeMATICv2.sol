// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

interface ITruStakeMATICv2 {
    // --- Events ---

    /// @notice Emitted on initialize.
    /// @dev params same as initialize function.
    event StakerInitialized(
        address _stakingTokenAddress,
        address _stakeManagerContractAddress,
        address _validatorShareContractAddress,
        address _whitelistAddress,
        address _treasuryAddress,
        uint256 _phi,
        uint256 _cap,
        uint256 _distPhi
    );

    // user tracking

    /// @notice Emitted on user deposit.
    /// @param _user user which made the deposit tx.
    /// @param _treasuryShares newly minted shares added to the treasury user's balance.
    /// @param _userShares newly minted shares added to the depositing user's balance.
    /// @param _amount amount of MATIC transferred by user into the staker.
    /// @param _stakedAmount _amount + any auto-claimed MATIC rewards sitting in the
    /// staker from previous deposits or withdrawal requests made by any user.
    /// @param _totalAssets auto-claimed MATIC rewards that will sit in the staker
    /// until the next deposit made by any user.
    event Deposited(
        address indexed _user,
        uint256 _treasuryShares,
        uint256 _userShares,
        uint256 _amount,
        uint256 _stakedAmount,
        uint256 _totalAssets
    );

    /// @notice Emitted on user requesting a withdrawal.
    /// @param _user user which made the withdraw request tx.
    /// @param _treasuryShares newly minted shares added to the treasury user's balance
    /// (fees taken: shares are newly minted as a result of the auto-claimed MATIC rewards).
    /// @param _userShares burnt shares removed from the depositing user's balance.
    /// @param _amount amount of MATIC unbonding, which will be claimable by user in
    /// 80 checkpoints.
    /// @param _totalAssets auto-claimed MATIC rewards that will sit in the staker
    /// until the next deposit made by any user.
    /// @param _unbondNonce nonce of this unbond, which will be passed into the function
    /// withdrawClaim(uint256 _unbondNonce)` in 80 checkpoints in order to claim this
    /// the amount from this request.
    /// @param _epoch the current checkpoint the stake manager is at, used to track how
    /// how far from claiming the request is.
    event WithdrawalRequested(
        address indexed _user,
        uint256 _treasuryShares,
        uint256 _userShares,
        uint256 _amount,
        uint256 _totalAssets,
        uint256 indexed _unbondNonce,
        uint256 indexed _epoch
    );

    /// @notice Emitted on user claiming a withdrawal.
    /// @param _user user which made the withdraw claim tx.
    /// @param _unbondNonce nonce of the original withdrawal request, which was passed
    /// into the `withdrawClaim` function.
    /// @param _amount amount of MATIC claimed from staker (originally from stake manager).
    event WithdrawalClaimed(address indexed _user, uint256 indexed _unbondNonce, uint256 _amount);

    // global tracking

    /// @notice Emitted on rewards compound call.
    /// @param _amount amount of MATIC moved from rewards on the validator to staked funds.
    /// @param _shares newly minted shares added to the treasury user's balance (fees taken).
    event RewardsCompounded(uint256 indexed _amount, uint256 indexed _shares);

    // allocations

    /// @notice Emitted on allocation.
    /// @param _distributor address of user who has allocated to someone else.
    /// @param _recipient address of user to whom something was allocated.
    /// @param _individualAmount total amount allocated to recipient by this distributor.
    /// @param _individualNum average share price numerator at which allocations occurred.
    /// @param _individualDenom average share price denominator at which allocations occurred.
    /// @param _totalAmount total amount distributor has allocated.
    /// @param _totalNum average share price numerator at which distributor allocated.
    /// @param _totalDenom average share price denominator at which distributor allocated.
    /// @param _strict bool to determine whether deallocation of funds allocated here should
    /// be subject to checks or not.
    event Allocated(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _individualAmount,
        uint256 _individualNum,
        uint256 _individualDenom,
        uint256 _totalAmount,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice Emitted on deallocations.
    /// @param _distributor address of user who has allocated to someone else.
    /// @param _recipient address of user to whom something was allocated.
    /// @param _individualAmount remaining amount allocated to recipient.
    /// @param _totalAmount total amount distributor has allocated.
    /// @param _totalNum average share price numerator at which distributor allocated.
    /// @param _totalDenom average share price denominator at which distributor allocated.
    /// @param _strict bool to determine whether the deallocation of these funds was
    /// subject to strictness checks or not.
    event Deallocated(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _individualAmount,
        uint256 _totalAmount,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice Emitted on reallocations.
    /// @param _distributor address of user who is switching allocation recipient.
    /// @param _oldRecipient previous recipient of allocated rewards.
    /// @param _newRecipient new recipient of allocated rewards.
    /// @param _newAmount matic amount stored in allocation of the new recipient.
    /// @param _newNum numerator of share price stored in allocation of the new recipient.
    /// @param _newDenom denominator of share price stored in allocation of the new recipient.
    event Reallocated(
        address indexed _distributor,
        address indexed _oldRecipient,
        address indexed _newRecipient,
        uint256 _newAmount,
        uint256 _newNum,
        uint256 _newDenom
    );

    /// @notice Emitted when rewards are distributed.
    /// @param _distributor address of user who has allocated to someone else.
    /// @param _recipient address of user to whom something was allocated.
    /// @param _amount amount of matic being distributed.
    /// @param _shares amount of shares being distributed.
    /// @param _individualNum average share price numerator at which distributor allocated.
    /// @param _individualDenom average share price numerator at which distributor allocated.
    /// @param _totalNum average share price numerator at which distributor allocated.
    /// @param _totalDenom average share price denominator at which distributor allocated.
    /// @param _strict bool to determine whether these funds came from the strict or
    /// non-strict allocation mappings.
    event DistributedRewards(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _amount,
        uint256 _shares,
        uint256 _individualNum,
        uint256 _individualDenom,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice Emitted when rewards are distributed.
    /// @param _distributor address of user who has allocated to someone else.
    /// @param _curNum current share price numerator.
    /// @param _curDenom current share price denominator.
    /// @param _strict bool to determine whether these funds came from the strict or
    /// non-strict allocation mappings.
    event DistributedAll(address indexed _distributor, uint256 _curNum, uint256 _curDenom, bool indexed _strict);

    // setter tracking

    event SetValidatorShareContract(address indexed _oldValidatorShareContract, address indexed _newValidatorShareContract);

    event SetWhitelist(address indexed _oldWhitelistAddress, address indexed _newWhitelistAddress);

    event SetTreasury(address indexed _oldTreasuryAddress, address indexed _newTreasuryAddress);

    event SetCap(uint256 indexed _oldCap, uint256 indexed _newCap);

    event SetPhi(uint256 indexed _oldPhi, uint256 indexed _newPhi);

    event SetDistPhi(uint256 indexed _oldDistPhi, uint256 indexed _newDistPhi);

    event SetEpsilon(uint256 indexed _oldEpsilon, uint256 indexed _newEpsilon);

    event SetAllowStrict(bool indexed _oldAllowStrict, bool indexed _newAllowStrict);

    // --- Errors ---

    /// @notice Error thrown when the phi value is larger than the phi precision constant.
    error PhiTooLarge();

    /// @notice Error thrown when a user tries to interact with a whitelisted-only function.
    error UserNotWhitelisted();

    /// @notice Error thrown when a user tries to deposit under 1 MATIC.
    error DepositUnderOneMATIC();

    /// @notice Error thrown when a deposit causes the vault staked amount to surpass the cap.
    error DepositSurpassesVaultCap();

    /// @notice Error thrown when a user tries to request a withdrawal with an amount larger
    /// than their shares entitle them to.
    error WithdrawalAmountTooLarge();

    /// @notice Error thrown when a user tries to request a withdrawal of amount zero.
    error WithdrawalRequestAmountCannotEqualZero();

    /// @notice Error thrown when a user tries to claim a withdrawal they did not request.
    error SenderMustHaveInitiatedWithdrawalRequest();

    /// @notice Error used in ERC-4626 integration, thrown when user tries to act on
    /// behalf of different user.
    error SenderAndOwnerMustBeReceiver();

    /// @notice Error used in ERC-4626 integration, thrown when user tries to transfer
    /// or approve to zero address.
    error ZeroAddressNotSupported();

    /// @notice Error thrown when user allocates more MATIC than available.
    error InsufficientDistributorBalance();

    /// @notice Error thrown when user calls distributeRewards for
    /// recipient with nothing allocated to them.
    error NoRewardsAllocatedToRecipient();

    /// @notice Error thrown when user calls distributeRewards when the allocation
    /// share price is the same as the current share price.
    error NothingToDistribute();

    /// @notice Error thrown when a user tries to a distribute rewards allocated by
    /// a different user.
    error OnlyDistributorCanDistributeRewards();

    /// @notice Error thrown when a user tries to transfer more share than their
    /// balance subtracted by the total amount they have strictly allocated.
    error ExceedsUnallocatedBalance();

    /// @notice Error thrown when a user attempts to allocate less than one MATIC.
    error AllocationUnderOneMATIC();

    /// @notice Error thrown when a user tries to reallocate from a user they do
    /// not currently have anything allocated to.
    error AllocationNonExistent();

    /// @notice Error thrown when a user tries to strictly allocate but `allowStrict`
    /// has been set to false.
    error StrictAllocationDisabled();

    /// @notice Error thrown when the distribution fee is higher than the fee precision.
    error DistPhiTooLarge();

    /// @notice Error thrown when new cap is less than current amount staked.
    error CapTooLow();

    /// @notice Error thrown when epsilon is set too high.
    error EpsilonTooLarge();

    /// @notice Error thrown when deallocation is greater than allocated amount.
    error ExcessDeallocation();
}