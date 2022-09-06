// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ENDLESS DREAM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    ╔═╗╔╗╔╔╦╗╦  ╔═╗╔═╗╔═╗  ╔╦╗╦═╗╔═╗╔═╗╔╦╗    //
//    ║╣ ║║║ ║║║  ║╣ ╚═╗╚═╗   ║║╠╦╝║╣ ╠═╣║║║    //
//    ╚═╝╝╚╝═╩╝╩═╝╚═╝╚═╝╚═╝  ═╩╝╩╚═╚═╝╩ ╩╩ ╩    //
//    BY HECTOROZ                               //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract ED is ERC721Creator {
    constructor() ERC721Creator("ENDLESS DREAM", "ED") {}
}