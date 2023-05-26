// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Stages of Life 2 Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    This is my ASCII Mark. - Yaga    //
//                                     //
//                                     //
/////////////////////////////////////////


contract Sol2Ed is ERC1155Creator {
    constructor() ERC1155Creator("The Stages of Life 2 Editions", "Sol2Ed") {}
}