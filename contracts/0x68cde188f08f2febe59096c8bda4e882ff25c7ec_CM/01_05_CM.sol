// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checked Memes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    _________     _____       //
//    \_   ___ \   /     \      //
//    /    \  \/  /  \ /  \     //
//    \     \____/    Y    \    //
//     \______  /\____|__  /    //
//            \/         \/     //
//                              //
//                              //
//                              //
//////////////////////////////////


contract CM is ERC721Creator {
    constructor() ERC721Creator("Checked Memes", "CM") {}
}