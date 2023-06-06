// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Single1155 is ExecutorCore {
    
    /**
     * #0.5
     */
    function recordSale1155(address tokenContract, uint256 tokenId, uint256 count, uint256 price, address priceCurrency) external {
        _requireOnlyValidSender();
        _recordSale1155(tokenContract, tokenId, count, price, priceCurrency);
    }

    /**
     * #1.5
     */
    function executeSaleUsd1155(
        uint256 count,
        uint256 price,
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        _transfer1155(count, price, _priceCurrencyUSD, tokenId, tokenContract, seller, buyer);
    }

    /**
     * #2.5
     */
    function executeSaleEth1155(
        uint256 count, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        _transfer1155(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds);   
    }

    /**
     * #3.5
     */
    function executeSaleToken1155(
        uint256 count, 
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        _transfer1155(count, price, priceCurrency, tokenId, tokenContract, seller, buyer);
        _transfer20(sellerProceeds, priceCurrency, seller);
    }

    /**
     * #4.5
     */
    function executeSaleReceiver1eth1155(
        uint256 count, 
        address receiverCreator, 
        uint256 receiverAmount, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        _transfer1155(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds); 
        _transferEth(receiverCreator, receiverAmount); 
    }

    /**
     * #5.5
     */
    function executeSaleReceiver1token1155(
        uint256 count,
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency, 
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer1155(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        _transfer20(receiverAmount, priceCurrency, receiverCreator);
    }

    /**
     * #6.5
     */
    function executeSaleReceiverNeth1155(
        uint256 count,
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEvent calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer1155(count, ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transferEth(seller, ne.sellerProceeds);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transferEth(receiverCreators[i], receiverAmounts[i]);
        }
    }

    /**
     * #7.5
     */
    function executeSaleReceiverNtoken1155(
        uint256 count, 
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer1155(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transfer20(receiverAmounts[i], priceCurrency, receiverCreators[i]);
        }
    }

}