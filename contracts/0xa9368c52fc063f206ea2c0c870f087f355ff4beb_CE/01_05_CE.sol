// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evenstar Mermaids
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//     +-+-+-+-+-+-+-+-+    //
//     |E|V|E|N|S|T|A|R|    //
//     +-+-+-+-+-+-+-+-+    //
//                          //
//                          //
//                          //
//////////////////////////////


contract CE is ERC721Creator {
    constructor() ERC721Creator("Evenstar Mermaids", "CE") {}
}