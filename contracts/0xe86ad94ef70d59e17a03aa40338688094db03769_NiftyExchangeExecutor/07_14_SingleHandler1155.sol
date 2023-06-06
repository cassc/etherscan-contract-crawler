// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract SingleHandler1155 is ExecutorCore {
    
    /**
     * #2.5x
     */
    function executeSaleEth1155handler(
        uint256 count,
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        bool success = _transfer1155handler(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
        } else {
            _transferEth(buyer, refund);
        } 
    }

    /**
     * #3.5x
     */
    function executeSaleToken1155handler(
        uint256 count,
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        bool success = _transfer1155handler(count, price, priceCurrency, tokenId, tokenContract, seller, buyer);
        if(success){
            _transfer20(sellerProceeds, priceCurrency, seller);
        } else {
            _transfer20(refund, priceCurrency, buyer);
        }
    }

    /**
     * #4.5x
     */
    function executeSaleReceiver1eth1155handler(
        uint256 count,
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
        bool success = _transfer1155handler(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
            _transferEth(receiverCreator, receiverAmount);
        } else {
            _transferEth(buyer, refund);
        }
    }

    /**
     * #5.5x
     */
    function executeSaleReceiver1token1155handler(
        uint256 count,
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency, 
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer1155handler(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        if(success){
            _transfer20(ne.sellerProceeds, priceCurrency, seller);
            _transfer20(receiverAmount, priceCurrency, receiverCreator);
        } else {
            _transfer20(ne.refund, priceCurrency, buyer);
        }
    }

    /**
     * #6.5x
     */
    function executeSaleReceiverNeth1155handler(
        uint256 count,
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEventHandler calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer1155handler(count, ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, ne.buyer);
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
     * #7.5x
     */
    function executeSaleReceiverNtoken1155handler(
        uint256 count,
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer1155handler(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, buyer);
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