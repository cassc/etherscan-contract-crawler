// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DNA 001 BY FARRAH CARBONELL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//    88888888ba,    888b      88         db             //
//    88      `"8b   8888b     88        d88b            //
//    88        `8b  88 `8b    88       d8'`8b           //
//    88         88  88  `8b   88      d8'  `8b          //
//    88         88  88   `8b  88     d8YaaaaY8b         //
//    88         8P  88    `8b 88    d8""""""""8b        //
//    88      .a8P   88     `8888   d8'        `8b       //
//    88888888Y"'    88      `888  d8'          `8b      //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract DNA is ERC721Creator {
    constructor() ERC721Creator("DNA 001 BY FARRAH CARBONELL", "DNA") {}
}