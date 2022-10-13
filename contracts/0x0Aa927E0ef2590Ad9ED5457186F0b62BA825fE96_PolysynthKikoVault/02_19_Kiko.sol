// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

library Kiko {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    uint256 internal constant RATIO_MULTIPLIER = 10**4;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // Number of underlying assets in the vault
        uint8 basketSize;
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in Kiko Vault
        address asset;
        // Underlying assets of the options sold by vault
        address[] underlyings;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
        // Knock in barrier for the vault
        uint16 kiBar;
        // Knock out barrier for the vault
        uint16 koBar;
        // Strike ratio for the vault
        uint16 strikeRatio;
        // Vault lifecycle duration in seconds
        uint256 vaultPeriod;
    }
    
    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rKIKO tokens
        uint128 totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint128 queuedWithdrawShares;
    }

    struct OptionState {
        // Whether the vault has knocked in
        bool hasKnockedIn;
        // Whether the vault has knocked out
        bool hasKnockedOut;
        // Whether the previous round has been settled
        bool isSettled;
        // Number of days the vault was active, increments every day KO hasn't happened
        uint16 vaultActiveDays;
        // Coupon rate for current option
        uint256 couponRate;
        // Borrow rate for current option
        uint256 borrowRate;
        // Whether the MM has borrowed the collateral
        bool isBorrowed;
        // Expiry of the current round
        uint256 expiry;
        // Timestamp at the time of knock out
        uint256 koTime;
        // Timestamp at the time of last observation
        uint256 lastObservation;
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
}