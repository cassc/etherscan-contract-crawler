// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gm☕️ we love the photographers!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    gm☕️    //
//            //
//            //
////////////////


contract gm is ERC1155Creator {
    constructor() ERC1155Creator(unicode"gm☕️ we love the photographers!", "gm") {}
}