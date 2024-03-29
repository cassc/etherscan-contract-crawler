// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JD ARCHIVE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//    ████████╗██╗░░██╗███████╗  ░█████╗░██████╗░░█████╗░██╗░░██╗██╗██╗░░░██╗███████╗    //
//    ╚══██╔══╝██║░░██║██╔════╝  ██╔══██╗██╔══██╗██╔══██╗██║░░██║██║██║░░░██║██╔════╝    //
//    ░░░██║░░░███████║█████╗░░  ███████║██████╔╝██║░░╚═╝███████║██║╚██╗░██╔╝█████╗░░    //
//    ░░░██║░░░██╔══██║██╔══╝░░  ██╔══██║██╔══██╗██║░░██╗██╔══██║██║░╚████╔╝░██╔══╝░░    //
//    ░░░██║░░░██║░░██║███████╗  ██║░░██║██║░░██║╚█████╔╝██║░░██║██║░░╚██╔╝░░███████╗    //
//    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░░╚═╝░░░╚══════╝    //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract ARCHVE is ERC721Creator {
    constructor() ERC721Creator("JD ARCHIVE", "ARCHVE") {}
}