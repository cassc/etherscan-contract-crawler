// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Basaia Jam Sessions I
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    3a5a1a                  //
//    argentinan artist       //
//    paint with auto tune    //
//                            //
//                            //
////////////////////////////////


contract BASA is ERC1155Creator {
    constructor() ERC1155Creator("Basaia Jam Sessions I", "BASA") {}
}