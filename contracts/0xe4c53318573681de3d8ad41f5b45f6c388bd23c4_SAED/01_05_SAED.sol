// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sandra's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     .d8888b.        d8888 8888888888 8888888b.      //
//    d88P  Y88b      d88888 888        888  "Y88b     //
//    Y88b.          d88P888 888        888    888     //
//     "Y888b.      d88P 888 8888888    888    888     //
//        "Y88b.   d88P  888 888        888    888     //
//          "888  d88P   888 888        888    888     //
//    Y88b  d88P d8888888888 888        888  .d88P     //
//     "Y8888P" d88P     888 8888888888 8888888P"      //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract SAED is ERC1155Creator {
    constructor() ERC1155Creator("Sandra's Editions", "SAED") {}
}