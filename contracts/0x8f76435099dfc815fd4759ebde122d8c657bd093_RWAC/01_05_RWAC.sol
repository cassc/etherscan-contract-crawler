// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rebel with a Cello
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    888 88e  Y8b Y8b Y888P     e Y8b       e88'Y88       //
//    888 888D  Y8b Y8A Y8A     d8b Y8N     d888  'S       //
//    888 88"    Y8b Y8b Y     d888b Y8b   C8888           //
//    888 b,      Y8b Y8b     d888888888b   Y888  ,d       //
//    888 88b,     Y8P Y     d8888888b Y8b   "88,d88       //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract RWAC is ERC721Creator {
    constructor() ERC721Creator("Rebel with a Cello", "RWAC") {}
}