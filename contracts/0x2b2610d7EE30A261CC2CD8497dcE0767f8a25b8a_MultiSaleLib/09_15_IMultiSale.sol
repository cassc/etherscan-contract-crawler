//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TokenType } from "./IToken.sol";
import { VariablePriceContract } from "./IVariablePrice.sol";

/// @Nnotice the payment type for the token
enum PaymentType {
    Ether,
    ERC20
}

/// @notice the multisale purchase
struct MultiSalePurchase {
    uint256 multiSaleId;
    address purchaser;
    address receiver;
    uint256 quantity;
}
    
/// @notice the merkle proof for the token sale
struct MultiSaleProof {
    uint256 leaf;
    uint256 total;
    bytes32[] merkleProof;
}

/// @notice the settings for the token sale,
struct MultiSaleSettings {

    TokenType tokenType; // the type of token being sold
    address token; // the token being sold
    uint256 tokenHash; // the token hash being sold. set to 0 to autocreate hash

    uint256 whitelistHash; // the whitelist hash. set to 0 for owhitelist
    bool whitelistOnly; // if true, only whitelisted addresses can purchase

    // owner and payee
    address owner; // the owner of the contract
    address payee; // the payee of the co ntract

    string symbol; // the symbol of the token
    string name; // the name of the token
    string description; // the description of the token

    // open state
    bool openState; // open or closed
    uint256 startTime; // block number when the sale starts
    uint256 endTime; // block number when the sale ends

    // quantitiesp
    uint256 maxQuantity; // max number of tokens that can be sold
    uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
    uint256 minQuantityPerSale; // min number of tokens that can be sold per sale
    uint256 maxQuantityPerAccount; // max number of tokens that can be sold per account

    PaymentType paymentType; // the type of payment that is being used
    address tokenAddress; // the address of the payment token, if payment type is TOKEN

    uint256 nextSaleId; // the next sale id
    VariablePriceContract price; // the variable prices

}

/// @notice the multi sale contract
struct MultiSaleContract {
    MultiSaleSettings settings;

    uint256 nonce;
    uint256 totalPurchased;
        
    mapping(address => uint256) purchased;
    mapping(uint256 => uint256) _redeemedData;
    mapping(address => uint256) _redeemedDataQuantities;
    mapping(address => uint256) _totalDataQuantities;
}

/// @notice the multi sale storage
struct MultiSaleStorage {
    // the nonce
    uint256 tsnonce;
    mapping(uint256 => MultiSaleContract) _tokenSales; // token sale settings
    uint256[] _tokenSaleIds;
}


interface IMultiSale {

    // @notice emitted when a token sale is created
    event MultiSaleCreated(uint256 indexed tokenSaleId, MultiSaleSettings settings);

    /// @notice emitted when a token is opened
    event MultiSaleOpen (uint256 indexed tokenSaleId, MultiSaleSettings tokenSale);

    /// @notice emitted when a token is opened
    event MultiSaleClosed (uint256 indexed tokenSaleId);

    /// @notice emitted when a token is opened
    event MultiSaleSold (uint256 indexed tokenSaleId, address indexed purchaser, uint256[] tokenIds, bytes data);

    // token settings were updated
    event MultiSaleUpdated (uint256 indexed tokenSaleId, MultiSaleSettings tokenSale );

}