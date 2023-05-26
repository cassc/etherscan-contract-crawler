// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ICHISHOU ILLUSTRATION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//    ╦╔═╗╦ ╦╦╔═╗╦ ╦╔═╗╦ ╦  ╦╦  ╦  ╦ ╦╔═╗╔╦╗╦═╗╔═╗╔╦╗╦╔═╗╔╗╔    //
//    ║║  ╠═╣║╚═╗╠═╣║ ║║ ║  ║║  ║  ║ ║╚═╗ ║ ╠╦╝╠═╣ ║ ║║ ║║║║    //
//    ╩╚═╝╩ ╩╩╚═╝╩ ╩╚═╝╚═╝  ╩╩═╝╩═╝╚═╝╚═╝ ╩ ╩╚═╩ ╩ ╩ ╩╚═╝╝╚╝    //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract ICHI is ERC721Creator {
    constructor() ERC721Creator("ICHISHOU ILLUSTRATION", "ICHI") {}
}