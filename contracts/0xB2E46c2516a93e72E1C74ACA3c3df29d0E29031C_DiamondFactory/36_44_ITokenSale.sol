//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ITokenPrice.sol";

enum PaymentType {
    ETH,
    TOKEN
}

struct TokenSaleSettings {
    // the id of the token sale
    uint256 id;

    // owner and payee
    address owner; // the owner of the tokensale
    address payee; // the payee of the tokensale

    // mint information
    address tokenAddress; // the address of the token to mint on 
    uint256 tokenHash; // the token hash being sold. set to 0 to autocreate hash
    
    string symbol; // the symbol of the token
    string name; // the name of the token
    string description; // the description of the token

    uint256 startTime; // block number when the sale starts
    uint256 endTime; // block number when the sale ends
    bool openState; // open or closed
    
    // if id is zero then tokensale is public (no whitelist)
    uint256 whitelistId; 

        // quantities
    uint256 maxQuantity; // max number of tokens that can be sold
    uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
    uint256 minQuantityPerSale; // min number of tokens that can be sold per sale

    // inital price of the token sale
    VariablePriceContract salePrice;

    PaymentType paymentType; // the type of payment that is being used
    address paymentAddress; // the address of the payment token, if payment type is TOKEN

    string[] attributes; // the attributes of the token

}

/// @notice the settings for the token sale,
struct TokenSaleContract {
    // the user-controllable token sale settings
    TokenSaleSettings settings;

    // tracking whitelists
    uint256 tsnonce;

    mapping(address => uint256) _totalDataQuantities;
    mapping(address => uint256) _redeemedDataQuantities;
    
    uint256 totalPurchased;
    mapping(address => uint256) purchased;
}

/// @notice A token seller is a contract that can sell tokens to a token buyer.
/// The token buyer can buy tokens from the seller by paying a certain amount
/// of base currency to receive a certain amount of erc1155 tokens. the number
/// of tokens that can be bought is limited by the seller - the seller can
/// specify the maximum number of tokens that can be bought per transaction
/// and the maximum number of tokens that can be bought in total for a given
/// address. The seller can also specify the price of erc1155 tokens and how
/// that price increases per successful transaction.
interface IWhitelistTokenSale {

    /// @notice Get the token sale settings
    /// @return settings the token sale settings
    function tokenSaleSettings(uint256 tokenSaleId) external view returns (TokenSaleSettings memory settings);

    /// @notice the count of whitelist redemptions made by the address for the token sale
    function whitelistRedemptions(uint256 tokenSaleId, address recipient) external view returns (uint256 redeemed, uint256 total);

    /// @notice redeem tokens for airdrop
    function purchase(
        uint256 tokenSaleId, 
        address recipient, 
        uint256 amount, 
        uint256 index, 
        uint256 total, 
        bytes32[] memory merkleProof) external payable;

}