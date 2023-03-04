// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Enigmatic world
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//    ╔═╗╔╗╔╦╔═╗╔╦╗╔═╗╔╦╗╦╔═╗    //
//    ║╣ ║║║║║ ╦║║║╠═╣ ║ ║║      //
//    ╚═╝╝╚╝╩╚═╝╩ ╩╩ ╩ ╩ ╩╚═╝    //
//    ╦ ╦╔═╗╦═╗╦  ╔╦╗            //
//    ║║║║ ║╠╦╝║   ║║            //
//    ╚╩╝╚═╝╩╚═╩═╝═╩╝            //
//                               //
//                               //
//                               //
///////////////////////////////////


contract EW is ERC721Creator {
    constructor() ERC721Creator("Enigmatic world", "EW") {}
}