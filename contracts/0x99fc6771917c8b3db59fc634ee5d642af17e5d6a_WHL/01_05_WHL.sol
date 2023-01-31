// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xFcks Warhol Tribute
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    homage to the diva    //
//                          //
//                          //
//////////////////////////////


contract WHL is ERC721Creator {
    constructor() ERC721Creator("0xFcks Warhol Tribute", "WHL") {}
}