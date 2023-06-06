// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Batch721 is ExecutorCore {    

    /** 
     * 0
     */
    function recordSale721batch(
        address[] calldata tokenContract, 
        uint256[] calldata tokenId, 
        uint256[] calldata price, 
        address[] calldata priceCurrency) external {
        _requireOnlyValidSender();
        for (uint256 i = 0; i < tokenContract.length; i++) {
            _recordSale721(tokenContract[i], tokenId[i], price[i], priceCurrency[i]);
        }
    }

    /** 
     * 1 
     */
    function executeSaleUsd721batch(
        uint256[] calldata price, 
        uint256[] calldata tokenId, 
        address[] calldata tokenContract, 
        address[] calldata seller, 
        address[] calldata buyer) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < tokenContract.length; i++){
            _transfer721(price[i], _priceCurrencyUSD, tokenId[i], tokenContract[i], seller[i], buyer[i]);
        }
    }

    /**
     * 2
     */
    function executeSaleEth721batch(
        uint256[] calldata price, 
        uint256[] calldata sellerProceeds, 
        uint256[] calldata tokenId, 
        address[] calldata tokenContract, 
        address[] calldata seller, 
        address[] calldata buyer) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < tokenContract.length; i++){
            _transfer721(price[i], _priceCurrencyETH, tokenId[i], tokenContract[i], seller[i], buyer[i]);
            _transferEth(seller[i], sellerProceeds[i]);
        }    
    }

    /** 
     * 3
     */
    function executeSaleToken721batch( 
        address[] calldata priceCurrency, 
        NiftyEvent[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address currency = priceCurrency[i];
            _transfer721(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transfer20(ne[i].sellerProceeds, currency, seller);
        } 
    }

    /** 
     * 6
     */
    function executeSaleReceiverNeth721batch(
        address[][] calldata receiverCreators, 
        uint256[][] calldata receiverAmounts, 
        NiftyEvent[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            _transfer721(ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer); 
            _transferEth(seller, ne[i].sellerProceeds);
            for(uint256 j = 0; j < receiverCreators[i].length; j++){
                _transferEth(receiverCreators[i][j], receiverAmounts[i][j]);
            }
        } 
    }

    /**
     * 7
     */
    function executeSaleReceiverNtoken721batch(NiftyEventReceiver[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            address currency = ne[i].priceCurrency;
            _transfer721(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer); 
            _transfer20(ne[i].sellerProceeds, currency, seller);
            for(uint256 j = 0; j < ne[i].receiverCreators.length; j++){
                _transfer20(ne[i].receiverAmounts[j], currency, ne[i].receiverCreators[j]);
            }
        } 
    }

}