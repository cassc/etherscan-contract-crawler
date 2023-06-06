// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Single721 is ExecutorCore {

    /**
     * 0
     */
    function recordSale721(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address priceCurrency) external {
        _requireOnlyValidSender();
        _recordSale721(tokenContract, tokenId, price, priceCurrency);
    }

    /**
     * #1
     */
    function executeSaleUsd721(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address seller,
        address buyer) external {
        _requireOnlyValidSender();
        _transfer721(price, _priceCurrencyUSD, tokenId, tokenContract, seller, buyer);
    }

    /**
     * #2
     */
    function executeSaleEth721(
        uint256 tokenId, 
        address tokenContract,
        uint256 price, 
        address seller,
        uint256 sellerProceeds,
        address buyer) external payable {
        _requireOnlyValidSender();
        _transfer721(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds);
    }

    /**
     * #3
     */
    function executeSaleToken721(
        uint256 tokenId, 
        address tokenContract,
        uint256 price,
        address priceCurrency,
        address seller,
        uint256 sellerProceeds, 
        address buyer) external {
        _requireOnlyValidSender();
        _transfer721(price, priceCurrency, tokenId, tokenContract, seller, buyer);
        _transfer20(sellerProceeds, priceCurrency, seller);
    }

    /**
     * #4
     */
    function executeSaleReceiver1eth721(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address seller,
        uint256 sellerProceeds,
        address buyer,
        address receiverCreator, 
        uint256 receiverAmount) external payable {
        _requireOnlyValidSender();
        _transfer721(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds); 
        _transferEth(receiverCreator, receiverAmount); 
    }

    /**
     * #5
     */
    function executeSaleReceiver1token721(
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency,
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer721(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        _transfer20(receiverAmount, priceCurrency, receiverCreator);
    }

    /**
     * #6
     */
    function executeSaleReceiverNeth721(
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEvent calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer721(ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transferEth(seller, ne.sellerProceeds);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transferEth(receiverCreators[i], receiverAmounts[i]);
        }
    }

    /**
     * #7
     */
    function executeSaleReceiverNtoken721(
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer721(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transfer20(receiverAmounts[i], priceCurrency, receiverCreators[i]);
        }
    }

}