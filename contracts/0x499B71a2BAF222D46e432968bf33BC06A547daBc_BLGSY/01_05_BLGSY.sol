// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blogsy Genesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//    888 88b,   888         e88 88e       e88'Y88     dP"8   Y88b Y8P     //
//    888 88P'   888        d888 888b     d888  'Y    C8b Y    Y88b Y      //
//    888 8K     888       C8888 8888D   C8888 eeee    Y8b      Y88b       //
//    888 88b,   888  ,d    Y888 888P     Y888 888P   b Y8D      888       //
//    888 88P'   888,d88     "88 88"       "88 88"    8edP       888       //
//                                                                         //
//                                                                         //
//    Y88b Y8P    dP"8     e88'Y88      e88 88e     888       888 88b,     //
//     Y88b Y    C8b Y    d888  'Y     d888 888b    888       888 88P'     //
//      Y88b      Y8b    C8888 eeee   C8888 8888D   888       888 8K       //
//       888     b Y8D    Y888 888P    Y888 888P    888  ,d   888 88b,     //
//       888     8edP      "88 88"      "88 88"     888,d88   888 88P'     //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract BLGSY is ERC721Creator {
    constructor() ERC721Creator("Blogsy Genesis", "BLGSY") {}
}