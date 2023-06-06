// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../core/ExecutorCore.sol";

/**
 * 721/1155, ETH/USD/ERC-20, & 0/1/N Receivers, w/o refund 
 */
abstract contract Switcher is ExecutorCore {

    /**
     * @dev Takes as input an array of generalized objects, consisting of 
     * sale events that include tokens of type ERC-721, and ERC-1155. The
     * payment may have been made in ETH, USD, or an ERC-20 token. The number
     * of royalty receivers can be either 0, 1 or N.  
     */
    function executeSaleBatch(NiftyEventBatch[] calldata ne) external payable {
        _requireOnlyValidSender();  
        for (uint256 i = 0; i < ne.length; i++) {
            address currency = ne[i].priceCurrency; 
            uint256 sellerProceeds = ne[i].sellerProceeds;
            address seller = ne[i].seller; 
            if(ne[i].count == 0) {
                _transfer721(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            } else {
                _transfer1155(ne[i].count, ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            }
            _executeSwitcher(currency, sellerProceeds, seller, ne[i].receiverCreators, ne[i].receiverAmounts);
        }
    }

}