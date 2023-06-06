// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract SingleHandler721 is ExecutorCore {    

    /**
     * #2x
     */
    function executeSaleEth721handler(
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        bool success = _transfer721handler(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
        } else {
            _transferEth(buyer, refund);
        }
    }

    /**
     * #3x
     */
    function executeSaleToken721handler(
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        bool success = _transfer721handler(price, priceCurrency, tokenId, tokenContract, seller, buyer);
        if(success){
            _transfer20(sellerProceeds, priceCurrency, seller);
        } else {
            _transfer20(refund, priceCurrency, buyer);
        }
    }

    /**
     * #4x
     */
    function executeSaleReceiver1eth721handler(
        uint256 refund,
        address receiverCreator, 
        uint256 receiverAmount, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        bool success = _transfer721handler(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
            _transferEth(receiverCreator, receiverAmount);
        } else {
            _transferEth(buyer, refund);
        }
    }

    /**
     * #5x
     */
    function executeSaleReceiver1token721handler(
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency,
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer721handler(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, buyer);
        if(success){
            _transfer20(ne.sellerProceeds, priceCurrency, seller);
            _transfer20(receiverAmount, priceCurrency, receiverCreator);
        } else {
            _transfer20(ne.refund, priceCurrency, buyer);
        }
    }

    /**
     * #6x
     */
    function executeSaleReceiverNeth721handler(
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEventHandler calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer721handler(ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, ne.sellerProceeds);
            for(uint256 i = 0; i < receiverCreators.length; i++){
                _transferEth(receiverCreators[i], receiverAmounts[i]);
            }
        } else {
            _transferEth(buyer, ne.refund);
        }
    }

    /**
     * #7x
     */
    function executeSaleReceiverNtoken721handler(
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer721handler(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, buyer);
        if(success){
            _transfer20(ne.sellerProceeds, priceCurrency, seller);
            for(uint256 i = 0; i < receiverCreators.length; i++){
                _transfer20(receiverAmounts[i], priceCurrency, receiverCreators[i]);
            }
        } else {
            _transfer20(ne.refund, priceCurrency, buyer);
        }
    }

}