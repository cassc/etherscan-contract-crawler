// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JULY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    ─╔╗╔╦╗╔╗─╔═╦╗    //
//    ─║║║║║║║─╚╗║║    //
//    ╔╣║║║║║╚╗╔╩╗║    //
//    ╚═╝╚═╝╚═╝╚══╝    //
//                     //
//                     //
/////////////////////////


contract JULY is ERC721Creator {
    constructor() ERC721Creator("JULY", "JULY") {}
}