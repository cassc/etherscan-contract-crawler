// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My little world of fantasy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ╔╦╗╦  ╦ ╦╔═╗╔═╗╔═╗╔═╗╦ ╦      //
//    ║║║║  ║║║║ ║╠╣ ╠╣ ╚═╗╚╦╝      //
//    ╩ ╩╩═╝╚╩╝╚═╝╚  ╚  ╚═╝ ╩       //
//                                  //
//                                  //
//////////////////////////////////////


contract MLWOFFSY is ERC721Creator {
    constructor() ERC721Creator("My little world of fantasy", "MLWOFFSY") {}
}