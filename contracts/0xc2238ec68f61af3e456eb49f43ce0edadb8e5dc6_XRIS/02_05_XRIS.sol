// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xristophers Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    ██╗░░██╗██████╗░██╗░██████╗    //
//    ╚██╗██╔╝██╔══██╗██║██╔════╝    //
//    ░╚███╔╝░██████╔╝██║╚█████╗░    //
//    ░██╔██╗░██╔══██╗██║░╚═══██╗    //
//    ██╔╝╚██╗██║░░██║██║██████╔╝    //
//    ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═════╝░    //
//                                   //
//                                   //
///////////////////////////////////////


contract XRIS is ERC721Creator {
    constructor() ERC721Creator("Xristophers Art", "XRIS") {}
}