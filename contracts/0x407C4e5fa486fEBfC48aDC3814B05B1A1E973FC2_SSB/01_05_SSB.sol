// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Birthday Love’t
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    7 sins zoo    //
//                  //
//                  //
//////////////////////


contract SSB is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Birthday Love’t", "SSB") {}
}