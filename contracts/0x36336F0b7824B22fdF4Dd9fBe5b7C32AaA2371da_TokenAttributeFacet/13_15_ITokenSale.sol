//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

///
/// @notice A token seller is a contract that can sell tokens to a token buyer.
/// The token buyer can buy tokens from the seller by paying a certain amount
/// of base currency to receive a certain amount of erc1155 tokens. the number
/// of tokens that can be bought is limited by the seller - the seller can
/// specify the maximum number of tokens that can be bought per transaction
/// and the maximum number of tokens that can be bought in total for a given
/// address. The seller can also specify the price of erc1155 tokens and how
/// that price increases per successful transaction.
interface ITokenSale {

    struct TokenSaleEntry {
        address payable receiver;
        address sourceToken;
        uint256 sourceTokenId;
        address token;
        uint256 quantity;
        uint256 price;
        uint256 quantitySold;
    }

    event TokenSaleSet(address indexed token, uint256 indexed tokenId, uint256 price, uint256 quantity);
    event TokenSold(address indexed buyer, address indexed tokenAddress, uint256 indexed tokenId, uint256 salePrice);
    event TokensSet(address indexed tokenAddress, ITokenSale.TokenSaleEntry tokens);

}