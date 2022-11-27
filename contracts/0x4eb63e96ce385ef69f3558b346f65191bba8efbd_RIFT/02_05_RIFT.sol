// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE RIFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//       ▄▄▄▄▀ ▄  █ ▄███▄       █▄▄▄▄ ▄█ ▄████     ▄▄▄▄▀     //
//    ▀▀▀ █   █   █ █▀   ▀      █  ▄▀ ██ █▀   ▀ ▀▀▀ █        //
//        █   ██▀▀█ ██▄▄        █▀▀▌  ██ █▀▀        █        //
//       █    █   █ █▄   ▄▀     █  █  ▐█ █         █         //
//      ▀        █  ▀███▀         █    ▐  █       ▀          //
//              ▀                ▀         ▀                 //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract RIFT is ERC721Creator {
    constructor() ERC721Creator("THE RIFT", "RIFT") {}
}