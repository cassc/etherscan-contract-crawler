// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mega Super Bored Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//    ███╗░░░███╗░██████╗██████╗░░█████╗░    //
//    ████╗░████║██╔════╝██╔══██╗██╔══██╗    //
//    ██╔████╔██║╚█████╗░██████╦╝██║░░╚═╝    //
//    ██║╚██╔╝██║░╚═══██╗██╔══██╗██║░░██╗    //
//    ██║░╚═╝░██║██████╔╝██████╦╝╚█████╔╝    //
//    ╚═╝░░░░░╚═╝╚═════╝░╚═════╝░░╚════╝░    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MSBC is ERC721Creator {
    constructor() ERC721Creator("Mega Super Bored Club", "MSBC") {}
}