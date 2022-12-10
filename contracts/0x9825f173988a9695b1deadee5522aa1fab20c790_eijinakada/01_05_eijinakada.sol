// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eiji Nakada
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    eijinakada    //
//                  //
//                  //
//////////////////////


contract eijinakada is ERC721Creator {
    constructor() ERC721Creator("Eiji Nakada", "eijinakada") {}
}