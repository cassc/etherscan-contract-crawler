// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Montalut
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//     +-+-+-+-+-+-+-+-+    //
//     |M|o|n|t|a|l|u|t|    //
//     +-+-+-+-+-+-+-+-+    //
//                          //
//                          //
//                          //
//////////////////////////////


contract MONTA is ERC721Creator {
    constructor() ERC721Creator("Montalut", "MONTA") {}
}