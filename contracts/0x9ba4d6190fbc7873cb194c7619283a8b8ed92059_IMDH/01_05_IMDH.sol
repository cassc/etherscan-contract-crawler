// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IN MY DARKEST HOUR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    ██╗███╗   ███╗██████╗ ██╗  ██╗    //
//    ██║████╗ ████║██╔══██╗██║  ██║    //
//    ██║██╔████╔██║██║  ██║███████║    //
//    ██║██║╚██╔╝██║██║  ██║██╔══██║    //
//    ██║██║ ╚═╝ ██║██████╔╝██║  ██║    //
//    ╚═╝╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝    //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract IMDH is ERC721Creator {
    constructor() ERC721Creator("IN MY DARKEST HOUR", "IMDH") {}
}