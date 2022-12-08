// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Primitives
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    888888888888          88888888ba   88888888888  88      a8P       //
//         88               88      "8b  88           88    ,88'        //
//         88               88      ,8P  88           88  ,88"          //
//         88  8b,     ,d8  88aaaaaa8P'  88aaaaa      88,d88'           //
//         88   `Y8, ,8P'   88""""88'    88"""""      8888"88,          //
//         88     )888(     88    `8b    88           88P   Y8b         //
//         88   ,d8" "8b,   88     `8b   88           88     "88,       //
//         88  8P'     `Y8  88      `8b  88888888888  88       Y8b      //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract TXREK is ERC721Creator {
    constructor() ERC721Creator("Primitives", "TXREK") {}
}