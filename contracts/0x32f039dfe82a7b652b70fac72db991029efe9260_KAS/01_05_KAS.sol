// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kenny Schachter New
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Kenny Schachter    //
//                       //
//                       //
///////////////////////////


contract KAS is ERC721Creator {
    constructor() ERC721Creator("Kenny Schachter New", "KAS") {}
}