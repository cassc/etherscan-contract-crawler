// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Simple Game
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    A Simple Game By Around The Clock    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract ASG is ERC1155Creator {
    constructor() ERC1155Creator("A Simple Game", "ASG") {}
}