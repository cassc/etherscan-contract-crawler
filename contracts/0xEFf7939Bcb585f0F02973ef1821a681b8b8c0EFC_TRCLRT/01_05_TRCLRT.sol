// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tricil.art editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    tricil.art    //
//                  //
//                  //
//////////////////////


contract TRCLRT is ERC1155Creator {
    constructor() ERC1155Creator("tricil.art editions", "TRCLRT") {}
}