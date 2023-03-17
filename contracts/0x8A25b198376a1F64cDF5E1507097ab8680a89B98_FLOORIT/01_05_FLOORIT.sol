// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLOOR IT AND GTFO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    floor it    //
//    and gtfo    //
//                //
//                //
////////////////////


contract FLOORIT is ERC721Creator {
    constructor() ERC721Creator("FLOOR IT AND GTFO", "FLOORIT") {}
}