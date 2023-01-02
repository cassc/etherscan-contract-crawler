// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GMJW
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ╔═╗  ╔╦╗   ╦  ╦ ╦    //
//    ║ ╦  ║║║   ║  ║║║    //
//    ╚═╝  ╩ ╩  ╚╝  ╚╩╝    //
//                         //
//                         //
/////////////////////////////


contract GMJW is ERC721Creator {
    constructor() ERC721Creator("GMJW", "GMJW") {}
}