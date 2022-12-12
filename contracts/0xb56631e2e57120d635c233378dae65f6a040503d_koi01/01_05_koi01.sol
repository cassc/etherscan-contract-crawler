// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Koi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    |   /     o /          |    \     //
//    |__/ ,---..| ,---.,---.|---  |    //
//    |  \ |   ||| ,---||    |     |    //
//    `   ``---'`| `---^`    `---' |    //
//                \               /     //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract koi01 is ERC1155Creator {
    constructor() ERC1155Creator("Koi", "koi01") {}
}