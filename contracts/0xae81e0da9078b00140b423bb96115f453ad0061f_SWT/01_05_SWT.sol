// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seven Woodland Tales
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//           ╔═╗  ╔═╗  ╦  ╦  ╔═╗  ╔╗╔           //
//           ╚═╗  ║╣   ╚╗╔╝  ║╣   ║║║           //
//           ╚═╝  ╚═╝   ╚╝   ╚═╝  ╝╚╝           //
//    ╦ ╦  ╔═╗  ╔═╗  ╔╦╗  ╦    ╔═╗  ╔╗╔  ╔╦╗    //
//    ║║║  ║ ║  ║ ║   ║║  ║    ╠═╣  ║║║   ║║    //
//    ╚╩╝  ╚═╝  ╚═╝  ═╩╝  ╩═╝  ╩ ╩  ╝╚╝  ═╩╝    //
//          ╔╦╗  ╔═╗  ╦    ╔═╗  ╔═╗             //
//           ║   ╠═╣  ║    ║╣   ╚═╗             //
//           ╩   ╩ ╩  ╩═╝  ╚═╝  ╚═╝             //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SWT is ERC721Creator {
    constructor() ERC721Creator("Seven Woodland Tales", "SWT") {}
}