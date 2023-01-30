// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Water
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    W     W  AA  TTTTTT EEEE RRRR      //
//    W     W A  A   TT   E    R   R     //
//    W  W  W AAAA   TT   EEE  RRRR      //
//     W W W  A  A   TT   E    R R       //
//      W W   A  A   TT   EEEE R  RR     //
//                                       //
//                                       //
///////////////////////////////////////////


contract WATR is ERC1155Creator {
    constructor() ERC1155Creator("Water", "WATR") {}
}