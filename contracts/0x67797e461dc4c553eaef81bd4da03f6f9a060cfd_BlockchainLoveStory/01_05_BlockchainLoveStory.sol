// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blockchain Love Story
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    88          ,ad8888ba,  8b           d8 88888888888      //
//    88         d8"'    `"8b `8b         d8' 88               //
//    88        d8'        `8b `8b       d8'  88               //
//    88        88          88  `8b     d8'   88aaaaa          //
//    88        88          88   `8b   d8'    88"""""          //
//    88        Y8,        ,8P    `8b d8'     88               //
//    88         Y8a.    .a8P      `888'      88               //
//    88888888888 `"Y8888Y"'        `8'       88888888888      //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract BlockchainLoveStory is ERC721Creator {
    constructor() ERC721Creator("Blockchain Love Story", "BlockchainLoveStory") {}
}