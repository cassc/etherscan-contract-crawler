// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAGE SHIBARI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//    ╦  ╦╦╦╔╦╗╔═╗╔═╗╔═╗╦  ╦╦╦╔═╗╦ ╦╦╔╗ ╔═╗╦═╗╦╦  ╦╦╦    //
//    ╚╗╔╝║║║║║╠═╣║ ╦║╣ ╚╗╔╝║║╚═╗╠═╣║╠╩╗╠═╣╠╦╝║╚╗╔╝║║    //
//     ╚╝ ╩╩╩ ╩╩ ╩╚═╝╚═╝ ╚╝ ╩╩╚═╝╩ ╩╩╚═╝╩ ╩╩╚═╩ ╚╝ ╩╩    //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract MS777 is ERC721Creator {
    constructor() ERC721Creator("MAGE SHIBARI", "MS777") {}
}