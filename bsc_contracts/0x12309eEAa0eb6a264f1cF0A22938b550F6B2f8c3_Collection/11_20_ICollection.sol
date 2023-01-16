// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICollection {
    /**
     * @dev Set an account to be excluded/included from the minting limit.
     * @param account -> representing the account to set exclusion for.
     * @param isExcluded -> whether the account is excluded from the limit.
     * @return whether the exclusion was set successfully.
     */
    function setAccountExcludedFromMintingLimit(
        address account,
        bool isExcluded
    ) external returns (bool);

    /**
     * @dev Set the maximum amount of tokens that can be minted per account.
     * @param newMaxMintPerAccount -> representing the new maximum mint limit per account.
     * @return whether the max mint per account was set successfully.
     */
    function setMaxMintPerAccount(uint256 newMaxMintPerAccount)
        external
        returns (bool);

    /**
     * @dev Set the price of the tokens in wei.
     * @param newPrice -> representing the new token price in wei.
     * @return whether the price was set successfully.
     */
    function setPrice(uint256 newPrice) external returns (bool);

    /**
     * @dev Set the maximum total supply of tokens.
     * @param newMaxSupply -> representing the new maximum supply of tokens.
     * @return whether the max supply was set successfully.
     */
    function setMaxSupply(uint256 newMaxSupply) external returns (bool);

    /**
     * @dev Set the state of the minting limit.
     * @param isEnabled -> whether the minting limit is enabled.
     * @return whether the minting limit was set successfully.
     */
    function setMintingLimitState(bool isEnabled) external returns (bool);

    /**
     * @dev Set the state of the minting.
     * @param isEnabled -> whether the minting is enabled
     * @return whether the minting state was set successfully.
     */
    function setMintingState(bool isEnabled) external returns (bool);

    /**
     * @dev Set the base URI for the token.
     * @param newBaseURI -> representing the new base URI as a string.
     * @return whether the base uri was set successfully.
     */
    function setBaseURI(string memory newBaseURI) external returns (bool);

    /**
     * @dev Withdraw funds from the contract to a given address.
     * @param token -> representing the token to withdraw.
     * @param recipient -> representing the recipient to receive the funds.
     * @return whether the withdrawal of funds was successful.
     */
    function withdrawFunds(address token, address recipient)
        external
        returns (bool);

    /**
     * @dev Airdrop a specific amount of tokens to a given recipient.
     * @param amount -> representing the number of tokens to minted.
     * @param recipient -> representing the recipient of the tokens.
     * @return whether the airdrop was successful.
     */
    function airdrop(uint256 amount, address recipient) external returns (bool);

    /**
     * @dev minta specific amount of tokens.
     * @param token -> representing the payment option token.
     * @param amount -> representing the number of tokens to minted.
     * @return whether the mint was successful.
     */
    function mint(address token, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when the minting state is changed.
     * @param admin -> the admin that changed the minting state.
     * @param isEnabled -> representing the new minting state.
     */
    event MintStateChanged(address indexed admin, bool isEnabled);

    /**
     * @dev Emitted when the minting limit state is changed.
     * @param admin -> the admin that changed the minting limit state.
     * @param isEnabled -> representing the new minting limit state.
     */
    event MintLimitStateChanged(address indexed admin, bool isEnabled);

    /**
     * @dev Emitted when the minting limit is changed.
     * @param admin -> the admin that changed the minting limit.
     * @param newMaxMintPerAccount -> representing the new minting limit.
     */
    event MintLimitChanged(address indexed admin, uint256 newMaxMintPerAccount);

    /**
     * @dev Emitted when an account is excluded from minting limits.
     * @param admin -> the admin that changed the state of an account.
     * @param account -> the account that was excluded from minting limits.
     * @param isExcluded -> whether the account is excluded or not.
     */
    event ExcludedFromMintingLimit(
        address indexed admin,
        address account,
        bool isExcluded
    );

    /**
     * @dev Emitted when the maximum supply of tokens is changed.
     * @param admin -> the admin that changed the maximum supply.
     * @param newMaxSupply -> representing the new maximum supply.
     */
    event MaxSupplyChanged(address indexed admin, uint256 newMaxSupply);

    /**
     * @dev Emitted when the price per mint is changed.
     * @param admin -> the admin that changed the price per mint.
     * @param newPrice -> representing the new price per mint.
     */
    event PriceChanged(address indexed admin, uint256 newPrice);

    /**
     * @dev Emitted when a payment option is added.
     * @param admin -> the admin that added the payment option.
     * @param token -> the payment option that was added.
     */
    event PaymentOptionAdded(address indexed admin, address token);

    /**
     * @dev Emitted when a recipient is airdropped a token.
     * @param admin -> the admin that airdropped the token.
     * @param recipient -> the recipient of the airdropped tokens.
     * @param amount -> representing the amount of tokens.
     */
    event Airdropped(address admin, address recipient, uint256 amount);

    /**
     * @dev Emitted when the base URI is changed.
     * @param admin -> the admin that changed the base URI.
     * @param newBaseURI -> representing the new base URI.
     */
    event BaseURIChanged(address indexed admin, string newBaseURI);

    /**
     * @dev Emitted when funds are withdrawn from the contract.
     * @param admin -> the admin that withdrew the funds.
     * @param recipient -> the recipient of the funds.
     * @param amount -> representing the amount of funds withdrawn.
     */
    event FundsWithdrawn(
        address indexed admin,
        address recipient,
        uint256 amount
    );
}