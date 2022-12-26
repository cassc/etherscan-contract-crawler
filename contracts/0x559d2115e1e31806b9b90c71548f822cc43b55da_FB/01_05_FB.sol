// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Floating Buddies
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    FLOATING BUDDIES      //
//                          //
//    JUST KEEP FLOATING    //
//                          //
//                          //
//////////////////////////////


contract FB is ERC1155Creator {
    constructor() ERC1155Creator("Floating Buddies", "FB") {}
}