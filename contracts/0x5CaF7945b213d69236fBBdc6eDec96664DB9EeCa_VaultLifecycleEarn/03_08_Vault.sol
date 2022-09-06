// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Yield is scaled by 100 (10 ** 2) for PCT.
    uint256 internal constant YIELD_MULTIPLIER = 10**2;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in vault
        address asset;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct AllocationState {
        // Next Loan Term Length
        uint32 nextLoanTermLength;
        // Next Option Purchase Frequency
        uint32 nextOptionPurchaseFreq;
        // Current Loan Term Length
        uint32 currentLoanTermLength;
        // Current Option Purchase Frequency
        uint32 currentOptionPurchaseFreq;
        // Current Loan Allocation Percent
        uint16 loanAllocationPCT;
        // Current Option Purchase Allocation Percent
        uint16 optionAllocationPCT;
        // Loan Allocation in USD
        uint256 loanAllocation;
        // Option Purchase Allocation across all purchases
        uint256 optionAllocation;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for the strategy
        uint104 lockedAmount;
        // Amount that was locked for the strategy in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint128 totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint128 queuedWithdrawShares;
        // Last Loan Allocation Date
        uint64 lastEpochTime;
        // Last Option Purchase Date
        uint64 lastOptionPurchaseTime;
        // Amount of options bought in current round
        uint128 optionsBoughtInRound;
        // Amount of funds returned this round
        uint256 amtFundsReturned;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
    }

    /**
     * @param borrowerWeight is the borrow weight of the borrower
     * @param pendingBorrowerWeight is the pending borrow weight
     * @param exists is whether the borrower has already been added
     */
    struct BorrowerState {
        // Borrower exists
        bool exists;
        // Borrower weight
        uint128 borrowerWeight;
        // Borrower weight
        uint128 pendingBorrowerWeight;
    }
}