// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: xeccr
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    .~•‘°›  x e c c r  ‹°’•~.    //
//                                 //
//                                 //
/////////////////////////////////////


contract xccr is ERC721Creator {
    constructor() ERC721Creator("xeccr", "xccr") {}
}