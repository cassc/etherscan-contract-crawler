// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GBC Artworks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//      ___  ____   ___     //
//     / __)(  _ \ / __)    //
//    ( (_ \ ) _ (( (__     //
//     \___/(____/ \___)    //
//                          //
//                          //
//////////////////////////////


contract GBC is ERC1155Creator {
    constructor() ERC1155Creator("GBC Artworks", "GBC") {}
}