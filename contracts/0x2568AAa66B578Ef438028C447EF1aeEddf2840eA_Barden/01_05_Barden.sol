// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kyle Barden
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//    888    d8P           888              888888b.                         888                       //
//    888   d8P            888              888  "88b                        888                       //
//    888  d8P             888              888  .88P                        888                       //
//    888d88K     888  888 888  .d88b.      8888888K.   8888b.  888d888  .d88888  .d88b.  88888b.      //
//    8888888b    888  888 888 d8P  Y8b     888  "Y88b     "88b 888P"   d88" 888 d8P  Y8b 888 "88b     //
//    888  Y88b   888  888 888 88888888     888    888 .d888888 888     888  888 88888888 888  888     //
//    888   Y88b  Y88b 888 888 Y8b.         888   d88P 888  888 888     Y88b 888 Y8b.     888  888     //
//    888    Y88b  "Y88888 888  "Y8888      8888888P"  "Y888888 888      "Y88888  "Y8888  888  888     //
//                     888                                                                             //
//                Y8b d88P                                                                             //
//                 "Y88P"                                                                              //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Barden is ERC721Creator {
    constructor() ERC721Creator("Kyle Barden", "Barden") {}
}