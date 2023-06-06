// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract BatchHandler1155 is ExecutorCore {

    /**
     * 2.5x
     */
    function executeSaleEth1155batchHandler(
        uint256[] calldata count,
        NiftyEventHandler[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            bool success = _transfer1155handler(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transferEth(seller, ne[i].sellerProceeds);
            } else {
                _transferEth(buyer, ne[i].refund);
            } 
        } 
    }

    /**
     * 3.5x
     */
    function executeSaleToken1155batchHandler(
        uint256[] calldata count, 
        address[] calldata priceCurrency, 
        NiftyEventHandler[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){    
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            address currency = priceCurrency[i];
            bool success = _transfer1155handler(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transfer20(ne[i].sellerProceeds, currency, seller);
            } else {
                _transfer20(ne[i].refund, currency, buyer);
            }
        } 
    }

    /**
     * 6.5x
     */
    function executeSaleReceiverNeth1155batchHandler(
        uint256[] calldata count,
        address[][] calldata receiverCreators, 
        uint256[][] calldata receiverAmounts,  
        NiftyEventHandler[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            bool success = _transfer1155handler(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transferEth(seller, ne[i].sellerProceeds);
                for(uint256 j = 0; j < receiverCreators[i].length; j++){
                    _transferEth(receiverCreators[i][j], receiverAmounts[i][j]);
                }
            } else {
                _transferEth(buyer, ne[i].refund);
            }
        }
    }

    /**
     * 7.5x
     */
    function executeSaleReceiverNtoken1155batchHandler(uint256[] calldata count, NiftyEventReceiverHandler[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            address currency = ne[i].priceCurrency;
            address buyer = ne[i].buyer;
            bool success = _transfer1155handler(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transfer20(ne[i].sellerProceeds, currency, seller);
                for(uint256 j = 0; j < ne[i].receiverCreators.length; j++){
                    _transfer20(ne[i].receiverAmounts[j], currency, ne[i].receiverCreators[j]);
                }
            } else {
                _transfer20(ne[i].refund, currency, buyer);
            }
        }
    }

}