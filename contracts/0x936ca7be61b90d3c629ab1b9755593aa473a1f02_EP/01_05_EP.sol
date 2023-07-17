// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EPITOME
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ╔═╗╔═╗╦╔╦╗╔═╗╔╦╗╔═╗    //
//    ║╣ ╠═╝║ ║ ║ ║║║║║╣     //
//    ╚═╝╩  ╩ ╩ ╚═╝╩ ╩╚═╝    //
//                           //
//                           //
///////////////////////////////


contract EP is ERC721Creator {
    constructor() ERC721Creator("EPITOME", "EP") {}
}