// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MARK
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    88b           d88         db         88888888ba   88      a8P     //
//    888b         d888        d88b        88      "8b  88    ,88'      //
//    88`8b       d8'88       d8'`8b       88      ,8P  88  ,88"        //
//    88 `8b     d8' 88      d8'  `8b      88aaaaaa8P'  88,d88'         //
//    88  `8b   d8'  88     d8YaaaaY8b     88""""88'    8888"88,        //
//    88   `8b d8'   88    d8""""""""8b    88    `8b    88P   Y8b       //
//    88    `888'    88   d8'        `8b   88     `8b   88     "88,     //
//    88     `8'     88  d8'          `8b  88      `8b  88       Y8b    //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract MARK is ERC721Creator {
    constructor() ERC721Creator("MARK", "MARK") {}
}