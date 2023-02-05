// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { TokenType } from "../../lib/grappa/src/config/enums.sol";

library Vault {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    // Fees are 18-decimal places. For example: 20 * 10**18 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10 ** 18;

    // Otokens have 6 decimal places.
    uint256 internal constant DECIMALS = 6;

    // Otokens have 6 decimal places.
    uint256 internal constant UNIT = 10 ** 6;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _manager is the address that is responsible for advancing the vault
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _oracle is used to calculate NA
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _pauser is where withdrawn collateral exists waiting for client to withdraw
     * @param _auction is the auction contract
     * @param _instruments linear combination of options
     * @param _collaterals is the assets used in the vault
     * @param _auctionDuration is the duration of the gnosis auction
     * @param _leverageRatio how much of the funds are used in a round
     * @param _roundConfig sets the duration and expiration of options
     */
    struct InitParams {
        address _owner;
        address _manager;
        address _feeRecipient;
        address _oracle;
        uint256 _managementFee;
        uint256 _performanceFee;
        address _pauser;
        address _auction;
        Instrument[] _instruments;
        Collateral[] _collaterals;
        uint256 _auctionDuration;
        uint256 _leverageRatio;
        RoundConfig _roundConfig;
    }

    struct Collateral {
        // Grappa asset Id
        uint8 id;
        // ERC20 token address for the required collateral
        address addr;
        // the amount of decimals or token
        uint8 decimals;
    }

    struct Instrument {
        TokenType tokenType;
        // Indicated how much the vault is short or long this instrument in a structure
        int64 weight;
        // oracle for product
        address oracle;
        // Underlying asset of the options
        address underlying;
        // asset that the strike price is denominated in
        address strike;
        // Asset backing the option
        address collateral;
    }

    struct VaultParams {
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct OptionState {
        // Option that the vault is shorting / longing in the next cycle
        uint256[] nextOptions;
        // Option that the vault is currently shorting / longing
        uint256[] currentOptions;
        // Current premium per structure
        int256 premium;
        // Max number of structures possible to sell based on
        // = lockedBalance * leverageRatio
        uint256 maxStructures;
        // Total structures minted this round
        uint256 mintedStructures;
        // Amount of collateral required by the vault per structure
        uint256[] vault;
        // Amount of collateral required by the counterparty per structure
        uint256[] counterparty;
    }

    struct VaultState {
        // 32 byte slot 1
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint vault tokens
        uint128 totalPending;
        // store the number of shares queued for withdraw this round
        // zero'ed out at the start of each round, pauser withdraws all queued shares.
        uint128 queuedWithdrawShares;
    }

    struct DepositReceipt {
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct RoundConfig {
        // the duration of the option
        uint32 duration;
        // day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
        uint8 dayOfWeek;
        // hour of the day the option should expire. 0 is midnight
        uint8 hourOfDay;
    }
}