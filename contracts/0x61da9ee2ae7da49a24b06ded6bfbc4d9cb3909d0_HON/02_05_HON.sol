// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HoomyNoory
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    ╦ ╦╔═╗╔═╗╔╦╗╦ ╦  ╔╗╔╔═╗╔═╗╦═╗╦ ╦    //
//    ╠═╣║ ║║ ║║║║╚╦╝  ║║║║ ║║ ║╠╦╝╚╦╝    //
//    ╩ ╩╚═╝╚═╝╩ ╩ ╩   ╝╚╝╚═╝╚═╝╩╚═ ╩     //
//                                        //
//                                        //
////////////////////////////////////////////


contract HON is ERC721Creator {
    constructor() ERC721Creator("HoomyNoory", "HON") {}
}