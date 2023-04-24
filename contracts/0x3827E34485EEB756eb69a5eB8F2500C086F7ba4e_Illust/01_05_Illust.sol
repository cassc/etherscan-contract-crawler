// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2D Illustration
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ╦╦  ╦  ╦ ╦╔═╗╔╦╗╦═╗╔═╗╔╦╗╦╔═╗╔╗╔╔═╗    //
//    ║║  ║  ║ ║╚═╗ ║ ╠╦╝╠═╣ ║ ║║ ║║║║╚═╗    //
//    ╩╩═╝╩═╝╚═╝╚═╝ ╩ ╩╚═╩ ╩ ╩ ╩╚═╝╝╚╝╚═╝    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Illust is ERC721Creator {
    constructor() ERC721Creator("2D Illustration", "Illust") {}
}