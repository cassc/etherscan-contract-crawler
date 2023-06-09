// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @notice Initialization parameters for the vault.
 * @param _owner is the owner of the vault with critical permissions
 * @param _manager is the address that is responsible for advancing the vault
 * @param _feeRecipient is the address to receive vault performance and management fees
 * @param _oracle is used to calculate NAV
 * @param _whitelist is used to check address access permissions
 * @param _managementFee is the management fee pct.
 * @param _performanceFee is the performance fee pct.
 * @param _pauser is where withdrawn collateral exists waiting for client to withdraw
 * @param _collateralRatios is the array of round starting balances to set the initial collateral ratios
 * @param _collaterals is the assets used in the vault
 * @param _roundConfig sets the duration and expiration of options
 * @param _vaultParams set vaultParam struct
 */
struct InitParams {
    address _owner;
    address _manager;
    address _feeRecipient;
    address _oracle;
    address _whitelist;
    uint256 _managementFee;
    uint256 _performanceFee;
    address _pauser;
    uint256[] _collateralRatios;
    Collateral[] _collaterals;
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

struct VaultState {
    // 32 byte slot 1
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Amount that is currently locked for selling options
    uint96 lockedAmount;
    // Amount that was locked for selling options in the previous round
    // used for calculating performance fee deduction
    uint96 lastLockedAmount;
    // 32 byte slot 2
    // Stores the total tally of how much of `asset` there is
    // to be used to mint vault tokens
    uint96 totalPending;
    // store the number of shares queued for withdraw this round
    // zero'ed out at the start of each round, pauser withdraws all queued shares.
    uint128 queuedWithdrawShares;
}

struct DepositReceipt {
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Deposit amount, max 79,228,162,514 or 79 Billion ETH deposit
    uint96 amount;
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

// Used for fee calculations at the end of a round
struct VaultDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] roundStartingBalances;
    // current balances
    uint256[] currentBalances;
    // Total pending primary asset
    uint256 totalPending;
}

// Used when rolling funds into a new round
struct NAVDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] startingBalances;
    // Current collateral balances
    uint256[] currentBalances;
    // Used to calculate NAV
    address oracleAddr;
    // Expiry of the round
    uint256 expiry;
    // Pending deposits
    uint256 totalPending;
}

/**
 * @dev Position struct
 * @param tokenId option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}