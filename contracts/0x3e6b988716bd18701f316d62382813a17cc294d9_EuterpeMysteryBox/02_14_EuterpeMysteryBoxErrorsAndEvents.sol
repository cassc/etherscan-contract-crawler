// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title Errors and events for Euterpe Mystery Box.
 */
abstract contract EuterpeMysteryBoxErrorsAndEvents {
    /**
     * The caller is not user.
     */
    error CallerIsNotUser();

    /**
     * Whitelist mint is not enabled.
     */
    error WhitelistMintNotEnabled();

    /**
     * Mint for Euterpe Genesis SBT is not enabled.
     */
    error SBTMintNotEnabled();

    /**
     * Public mint is not enabled.
     */
    error PublicMintNotEnabled();

    /**
     * Redemption is not enabled.
     */
    error RedemptionNotEnabled();

    /**
     * Invalid params.
     */
    error InvalidParams();

    /**
     * Max supply exceeded.
     */
    error MaxSupplyExceeded();

    /**
     * Mint limit per wallet exceeded.
     */
    error MintLimitPerWalletExceeded();

    /**
     * The account is not whitelisted.
     */
    error NotWhitelisted();

    /**
     * The account is not the qualified Euterpe Genesis SBT holder.
     */
    error NotSBTHolder();

    /**
     * The account is not the token owner.
     */
    error NotTokenOwner();

    /**
     * Insufficient balance.
     */
    error InsufficientBalance();

    /**
     * Insufficient value.
     */
    error InsufficientValue();

    /**
     * @notice Triggered when the base URI set.
     */
    event BaseURISet(string baseURI);

    /**
     * @notice Triggered when the status changed.
     */
    event StatusChanged(uint8 status);

    /**
     * @notice Triggered when redemption is initiated.
     */
    event RedemptionRequested(address indexed account, uint256 indexed tokenId);

    /**
     * @notice Triggered when the balance withdrawn.
     */
    event Withdrawal(address indexed sender, uint256 amount);
}