// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Swap, Offer, OfferItem, SWAP_TYPEHASH, OFFER_TYPEHASH, OFFERITEM_TYPEHASH } from "./DTTDStructs.sol";
import { OfferItemType } from "./DTTDEnums.sol";


interface IDTTDSwap {

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogSwap(uint256 _swapNonce);
    event LogBlockSwap(bytes32 _swapHash);

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // EIP712 Domain Seperator
    function domainSeparator() external view returns (bytes32);

    // EIP712 hash for Swap struct
    function hashSwap(Swap calldata _swap) external view returns (bytes32);

    // Perform a swao with the given offers and signatures
    function performSwap(Swap calldata _swap, bytes[] calldata _signature) external payable;

    // Block a swap from being executed
    function blockSwap(Swap calldata _swap) external;

}