// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hash-One
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//     ██████╗ ██╗  ██╗    //
//    ██╔════╝ ██║  ██║    //
//    ███████╗ ███████║    //
//    ██╔═══██╗╚════██║    //
//    ╚██████╔╝     ██║    //
//     ╚═════╝      ╚═╝    //
//                         //
//                         //
/////////////////////////////


contract GBH1 is ERC721Creator {
    constructor() ERC721Creator("Hash-One", "GBH1") {}
}