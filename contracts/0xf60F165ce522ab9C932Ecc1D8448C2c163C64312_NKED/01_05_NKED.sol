// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nora Kartas ✦ Editions-1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     .------.------.------.------.    //
//     |      |      |      |      |    //
//     |      |      |      |      |    //
//     |      |      |      |      |    //
//     |      |      |      |      |    //
//     '------^------^------^------'    //
//             EDITIONS-1155            //
//             by Nora Kartas           //
//                                      //
//                                      //
//////////////////////////////////////////


contract NKED is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Nora Kartas ✦ Editions-1155", "NKED") {}
}