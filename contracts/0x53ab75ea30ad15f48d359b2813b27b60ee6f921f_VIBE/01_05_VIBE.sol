// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: !vibe machine – by Mills
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//      ██╗    ██╗   ██╗    ██╗    ██████╗     ███████╗     //
//      ██║    ██║   ██║    ██║    ██╔══██╗    ██╔════╝     //
//      ██║    ██║   ██║    ██║    ██████╔╝    █████╗       //
//      ╚═╝    ╚██╗ ██╔╝    ██║    ██╔══██╗    ██╔══╝       //
//      ██╗     ╚████╔╝     ██║    ██████╔╝    ███████╗     //
//      ╚═╝      ╚═══╝      ╚═╝    ╚═════╝     ╚══════╝     //
//                     Mills • 2022                         //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract VIBE is ERC721Creator {
    constructor() ERC721Creator(unicode"!vibe machine – by Mills", "VIBE") {}
}