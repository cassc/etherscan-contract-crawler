// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B Shows You the World
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Artist creating to express.    //
//                                   //
//                                   //
///////////////////////////////////////


contract World is ERC1155Creator {
    constructor() ERC1155Creator("B Shows You the World", "World") {}
}