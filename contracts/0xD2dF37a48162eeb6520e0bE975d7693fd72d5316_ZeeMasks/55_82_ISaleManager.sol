// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ISaleManager {
    /// @notice Thrown when attempting to call a whitelist-protected method, whilst a user has not been whitelisted..
    error NotWhitelisted();

    /// @notice thrown when minting limit has been reached.
    error MintingLimitReached();

    /// @notice Thrown when a user send invalid amount of funds to perform a token purchase.
    error InvalidFundsSent();

    /// @notice Thrown when a user attempts to purchase 0 tokens.
    error CannotPurchaseZeroTokens();

    /// @notice Thrown when a user is attempting to purchase tokens that overlap with the existing.
    error PurchaseExceedsCurrentTier();

    /// @notice Thrown when a user is attempting to purchase more tokens than the user cap allows on the current tier.
    error UserPurchasingCapReached();

    /// @notice thrown when not enough (or too much) ETH has been sent when performing a purchase.
    error InsufficientFunds();

    /// @notice Mint new token by paying the token price
    receive() external payable;

    /// @notice Mint new token by paying the token price.
    /// @param whitelistProof Optional whitelist proof. Used for validating the merkle root.
    ///        If Whitelist feature has been disabled, then this can be an empty array.
    /// @param count The amount of tokens to purchase in a single transaction.
    function buy(bytes32[] calldata whitelistProof, uint64 count) external payable;
}