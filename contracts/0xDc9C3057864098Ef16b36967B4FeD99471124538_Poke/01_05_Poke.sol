// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gotta catch em all
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Ϟ(๑⚈ ․̫ ⚈๑)⋆          //
//                          //
//    gotta catch em all    //
//                          //
//                          //
//////////////////////////////


contract Poke is ERC1155Creator {
    constructor() ERC1155Creator("gotta catch em all", "Poke") {}
}