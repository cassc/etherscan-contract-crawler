// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mandarinemarie's Gallery
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    |\/| _ ._  _| _ ._o._  _._ _  _ ._o _    //
//    |  |(_|| |(_|(_|| || |}_| | |(_|| |}_    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract MM is ERC1155Creator {
    constructor() ERC1155Creator("Mandarinemarie's Gallery", "MM") {}
}