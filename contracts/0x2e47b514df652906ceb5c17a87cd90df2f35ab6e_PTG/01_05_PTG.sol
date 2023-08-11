// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeTheGreat
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                                                                             //
//                                                                             //
//    This is to commemorate the life of Pepe the Frog. Thank you Matt Fury    //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract PTG is ERC1155Creator {
    constructor() ERC1155Creator("PepeTheGreat", "PTG") {}
}