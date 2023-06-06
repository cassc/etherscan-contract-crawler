// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../core/ExecutorCore.sol";

/**
 * 721/1155, ETH/USD/ERC-20, & 0/1/N Receivers, w/ refund 
 */
abstract contract SwitcherHandler is ExecutorCore {

    /**
     * @dev Takes as input an array of generalized objects, consisting of 
     * sale events that include tokens of type ERC-721, and ERC-1155. The
     * payment may have been made in ETH, USD, or an ERC-20 token. The number
     * of royalty receivers can be either 0, 1 or N.
     * 
     * @notice In the event the transfer is unsuccessful, the function will 
     * issue a refund to the buyer in the amount specified by the input 'refund'
     * parameter.  
     */
    function executeSaleBatchHandler(uint256[] calldata refund, NiftyEventBatch[] calldata ne) external payable {
        _requireOnlyValidSender();  
        for (uint256 i = 0; i < ne.length; i++) {
            address currency = ne[i].priceCurrency; 
            uint256 sellerProceeds = ne[i].sellerProceeds;
            address seller = ne[i].seller; 
            address buyer = ne[i].buyer; 
            if(ne[i].count == 0) {
                bool success = _transfer721handler(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
                if(success){
                    _executeSwitcher(currency, sellerProceeds, seller, ne[i].receiverCreators, ne[i].receiverAmounts);
                } else {
                    _executeRefund(refund[i], currency, buyer);
                }
            } else {
                bool success = _transfer1155handler(ne[i].count, ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
                if(success){
                    _executeSwitcher(currency, sellerProceeds, seller, ne[i].receiverCreators, ne[i].receiverAmounts);
                } else {
                    _executeRefund(refund[i], currency, buyer);
                }
            }
        }
    }
}