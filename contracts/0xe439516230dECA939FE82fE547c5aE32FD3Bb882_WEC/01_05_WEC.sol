// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WA-EVENT-COLLECTION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    WA-EVENT-COLLECTION    //
//                           //
//                           //
///////////////////////////////


contract WEC is ERC1155Creator {
    constructor() ERC1155Creator("WA-EVENT-COLLECTION", "WEC") {}
}