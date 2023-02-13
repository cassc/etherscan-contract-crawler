// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: artiz4n
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//     .d8b.  d8888b. d888888b d888888b d88888D   j88D  d8b   db     //
//    d8' `8b 88  `8D `~~88~~'   `88'   YP  d8'  j8~88  888o  88     //
//    88ooo88 88oobY'    88       88       d8'  j8' 88  88V8o 88     //
//    88~~~88 88`8b      88       88      d8'   V88888D 88 V8o88     //
//    88   88 88 `88.    88      .88.    d8' db     88  88  V888     //
//    YP   YP 88   YD    YP    Y888888P d88888P     VP  VP   V8P     //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract RTZN is ERC721Creator {
    constructor() ERC721Creator("artiz4n", "RTZN") {}
}