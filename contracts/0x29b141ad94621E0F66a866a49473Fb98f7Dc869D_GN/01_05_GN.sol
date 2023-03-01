// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: G.N.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      ________  _______        //
//     /  _____/  \      \       //
//    /   \  ___  /   |   \      //
//    \    \_\  \/    |    \     //
//     \______  /\____|__  /     //
//            \/         \/      //
//                               //
//                               //
//                               //
///////////////////////////////////


contract GN is ERC721Creator {
    constructor() ERC721Creator("G.N.", "GN") {}
}