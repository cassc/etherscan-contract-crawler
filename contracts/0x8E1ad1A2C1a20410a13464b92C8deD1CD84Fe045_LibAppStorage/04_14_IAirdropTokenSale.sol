//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ITokenPrice.sol";
import "./IAirdrop.sol";

/// @notice A token seller is a contract that can sell tokens to a token buyer.
/// The token buyer can buy tokens from the seller by paying a certain amount
/// of base currency to receive a certain amount of erc1155 tokens. the number
/// of tokens that can be bought is limited by the seller - the seller can
/// specify the maximum number of tokens that can be bought per transaction
/// and the maximum number of tokens that can be bought in total for a given
/// address. The seller can also specify the price of erc1155 tokens and how
/// that price increases per successful transaction.
interface IAirdropTokenSale {


    enum PaymentType {
        ETH,
        TOKEN
    }

    /// @notice the settings for the token sale,
    struct TokenSaleSettings {

        // addresses
        address contractAddress; // the contract doing the selling
        address token; // the token being sold
        uint256 tokenHash; // the token hash being sold. set to 0 to autocreate hash
        uint256 collectionHash; // the collection hash being sold. set to 0 to autocreate hash
        
        // owner and payee
        address owner; // the owner of the contract
        address payee; // the payee of the contract

        string symbol; // the symbol of the token
        string name; // the name of the token
        string description; // the description of the token

        // open state
        bool openState; // open or closed
        uint256 startTime; // block number when the sale starts
        uint256 endTime; // block number when the sale ends

        // quantities
        uint256 maxQuantity; // max number of tokens that can be sold
        uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
        uint256 minQuantityPerSale; // min number of tokens that can be sold per sale
        uint256 maxQuantityPerAccount; // max number of tokens that can be sold per account

        // inital price of the token sale
        ITokenPrice.TokenPriceData initialPrice;

        PaymentType paymentType; // the type of payment that is being used
        address tokenAddress; // the address of the payment token, if payment type is TOKEN

    }

    /// @notice emitted when a token is opened
    event TokenSaleOpen (uint256 tokenSaleId, TokenSaleSettings tokenSale );

    /// @notice emitted when a token is opened
    event TokenSaleClosed (uint256 tokenSaleId, TokenSaleSettings tokenSale );

    /// @notice emitted when a token is opened
    event TokenPurchased (uint256 tokenSaleId, address indexed purchaser, uint256 tokenId, uint256 quantity );

    // token settings were updated
    event TokenSaleSettingsUpdated (uint256 tokenSaleId, TokenSaleSettings tokenSale );

    /// @notice Get the token sale settings
    /// @return settings the token sale settings
    function getTokenSaleSettings(uint256 tokenSaleId) external view returns (TokenSaleSettings memory settings);

    /// @notice Updates the token sale settings
    /// @param settings - the token sake settings
    function updateTokenSaleSettings(uint256 iTokenSaleId, TokenSaleSettings memory settings) external;

    function initTokenSale(
        TokenSaleSettings memory tokenSaleInit,
        IAirdrop.AirdropSettings[] calldata settingsList
    ) external;
}