// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALEX ZERR: CANVAS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//     .d8888b.        d8888 888b    888 888     888     d8888  .d8888b.      //
//    d88P  Y88b      d88888 8888b   888 888     888    d88888 d88P  Y88b     //
//    888    888     d88P888 88888b  888 888     888   d88P888 Y88b.          //
//    888           d88P 888 888Y88b 888 Y88b   d88P  d88P 888  "Y888b.       //
//    888          d88P  888 888 Y88b888  Y88b d88P  d88P  888     "Y88b.     //
//    888    888  d88P   888 888  Y88888   Y88o88P  d88P   888       "888     //
//    Y88b  d88P d8888888888 888   Y8888    Y888P  d8888888888 Y88b  d88P     //
//     "Y8888P" d88P     888 888    Y888     Y8P  d88P     888  "Y8888P"      //
//                                                                            //
//    by Alex Zerr                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract CANVAS is ERC721Creator {
    constructor() ERC721Creator("ALEX ZERR: CANVAS", "CANVAS") {}
}