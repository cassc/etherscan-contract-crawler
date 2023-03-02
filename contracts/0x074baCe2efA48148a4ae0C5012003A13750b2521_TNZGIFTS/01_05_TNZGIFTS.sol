// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TNZ GIFT SHOP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    TNZ GIFT SHOP    //
//    NOW OPEN 24/7    //
//                     //
//                     //
/////////////////////////


contract TNZGIFTS is ERC1155Creator {
    constructor() ERC1155Creator("TNZ GIFT SHOP", "TNZGIFTS") {}
}