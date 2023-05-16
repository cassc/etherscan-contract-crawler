// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paintings by Process GReY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    GGG   RRRR  eeee Y   Y     //
//    G     R   R       Y Y      //
//    G  GG RRRR  eeee   Y       //
//    G   G R R          Y       //
//     GGG  R  RR eeee   Y       //
//                               //
//                               //
///////////////////////////////////


contract GReY is ERC1155Creator {
    constructor() ERC1155Creator("Paintings by Process GReY", "GReY") {}
}