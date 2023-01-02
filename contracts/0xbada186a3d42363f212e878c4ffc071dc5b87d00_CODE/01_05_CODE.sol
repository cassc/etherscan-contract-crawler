// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Code World
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ╔═╗╔═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦  ╔╦╗    //
//    ║  ║ ║ ║║║╣   ║║║║ ║╠╦╝║   ║║    //
//    ╚═╝╚═╝═╩╝╚═╝  ╚╩╝╚═╝╩╚═╩═╝═╩╝    //
//                                     //
//                                     //
/////////////////////////////////////////


contract CODE is ERC721Creator {
    constructor() ERC721Creator("Code World", "CODE") {}
}