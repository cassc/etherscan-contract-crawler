// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Batch1155 is ExecutorCore {    

    /** 
     * 0.5
     */
    function recordSale1155batch(
        uint256[] calldata count, 
        address[] calldata tokenContract, 
        uint256[] calldata tokenId,
        uint256[] calldata price, 
        address[] calldata priceCurrency) external {
        _requireOnlyValidSender();
        for (uint256 i = 0; i < tokenContract.length; i++) {
            _recordSale1155(tokenContract[i], tokenId[i], count[i], price[i], priceCurrency[i]);
        }
    }

    /** 
     * 1.5
     */
    function executeSaleUsd1155batch(
        uint256[] calldata count,
        uint256[] calldata price,
        uint256[] calldata tokenId, 
        address[] calldata tokenContract, 
        address[] calldata seller, 
        address[] calldata buyer) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < tokenContract.length; i++){
            _transfer1155(count[i], price[i], _priceCurrencyUSD, tokenId[i], tokenContract[i], seller[i], buyer[i]);
        }
    }

    /** 
     * 2.5
     */
    function executeSaleEth1155batch(
        uint256[] calldata count,
        NiftyEvent[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            _transfer1155(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, ne[i].seller, ne[i].buyer);
            _transferEth(ne[i].seller, ne[i].sellerProceeds);
        }  
    }

    /** 
     * 3.5
     */
    function executeSaleToken1155batch(
        uint256[] calldata count, 
        address[] calldata priceCurrency, 
        NiftyEvent[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address currency = priceCurrency[i];
            _transfer1155(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transfer20(ne[i].sellerProceeds, currency, seller);
        } 
    }

    /** 
     * 6.5
     */
    function executeSaleReceiverNeth1155batch(
        uint256[] calldata count,
        address[][] calldata receiverCreators, 
        uint256[][] calldata receiverAmounts,  
        NiftyEvent[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            _transfer1155(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transferEth(seller, ne[i].sellerProceeds);
            for(uint256 j = 0; j < receiverCreators[i].length; j++){
                _transferEth(receiverCreators[i][j], receiverAmounts[i][j]);
            }
        } 
    }

    /** 
     * 7.5
     */
    function executeSaleReceiverNtoken1155batch(uint256[] calldata count, NiftyEventReceiver[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            address currency = ne[i].priceCurrency;
            _transfer1155(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transfer20(ne[i].sellerProceeds, currency, seller);
            for(uint256 j = 0; j < ne[i].receiverCreators.length; j++){
                _transfer20(ne[i].receiverAmounts[j], currency, ne[i].receiverCreators[j]);
            }
        } 
    }

}