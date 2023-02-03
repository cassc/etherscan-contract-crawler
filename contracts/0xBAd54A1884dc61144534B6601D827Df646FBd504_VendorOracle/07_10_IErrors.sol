// SPDX-License-Identifier: No License
/**
 * @title Vendor Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

interface IErrors {
    /* ========== ERRORS ========== */
    /// @notice Error for if a mint ratio of 0 is passed in
    error MintRatio0();

    /// @notice Error for if pool is closed
    error PoolClosed();

    /// @notice Error for if pool is active
    error PoolActive();

    /// @notice Error for if price is not valid ex: -1
    error NotValidPrice();

    /// @notice Error for if not enough liquidity in pool
    error NotEnoughLiquidity();

    /// @notice Error for if balance is insufficient
    error InsufficientBalance();

    /// @notice Error for if address is not a pool
    error NotAPool();

    /// @notice Error for if address is different than lend token
    error DifferentLendToken();

    /// @notice Error for if address is different than collateral token
    error DifferentColToken();

    /// @notice Error for if owner addresses are different
    error DifferentPoolOwner();

    /// @notice Error for if a user has no debt
    error NoDebt();

    /// @notice Error for if user is trying to pay back more than the debt they have
    error DebtIsLess();

    /// @notice Error for if balance is not validated
    error TransferFailed();

    /// @notice Error for if user tries to interract with private pool
    error PrivatePool();

    /// @notice Error for if operations of this pool or potetntially all pools is stopped.
    error OperationsPaused();

    /// @notice Error for if lender paused borrowing.
    error BorrowingPaused();

    /// @notice Error for if Oracle not set.
    error OracleNotSet();

    /// @notice Error for if called by not owner
    error NotOwner();

    /// @notice Error for if illegal upgrade implementation
    error IllegalImplementation();

    /// @notice Error for if upgrades are not allowed at this time
    error UpgradeNotAllowed();

    /// @notice Error for if expiry is wrong
    error InvalidExpiry();

    /// @notice Error if the lender's fee is higher than what UI stated
    error FeeTooHigh();

    /// @notice Error for if address is not the pool factory or the pool owner
    error NoPermission();

    /// @notice Error for if array length is invalid
    error InvalidType();

    /// @notice Error for when the address passed as an argument is a zero address
    error ZeroAddress();

    /// @notice Error for if a mint id is not minted yet
    error LicenseNotFound();

    /// @notice Error for if a discount is too high
    error InvalidDiscount();

    ///@notice Error if not factory is trying to increment the amount of pools deployed by license
    error NotFactory();

    /// @notice Error for if address is not supported as lend token
    error LendTokenNotSupported();

    /// @notice Error for if address is not supported as collateral token
    error ColTokenNotSupported();

    /// @notice Error for if discount coming from license engine is over 100%
    error DiscountTooLarge();

    /// @notice Error for if lender fee is over 100%
    error FeeTooLarge();

    /// @notice Error for when unauthorized user tries to pause the pools or factory
    error NotAuthorized();

    /// @notice Error for when the address that was not granted the permissions is trying to claim the ownership
    error NotGranted();

    /// @notice Error for when the pegs setting on contruction of the oracle failed dur to bad arguments
    error InvalidParameters();

    /// @notice Error for when the token pair selected is not supported
    error InvalidTokenPair();

    /// @notice Error for when chainlink sent the incorrect price
    error RoundIncomplete();

    /// @notice Error for when chainlink sent the incorrect price
    error StaleAnswer();

    /// @notice Error for when the feed address is already set and owner is trying to alter it
    error FeedAlreadySet();

    /// @notice Error for when the pool is not whitelisted for rollover
    error PoolNotWhitelisted();
}