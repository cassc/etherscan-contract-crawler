// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memeberrys
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//    ███╗   ███╗██████╗     //
//    ████╗ ████║██╔══██╗    //
//    ██╔████╔██║██████╔╝    //
//    ██║╚██╔╝██║██╔══██╗    //
//    ██║ ╚═╝ ██║██████╔╝    //
//    ╚═╝     ╚═╝╚═════╝     //
//                           //
//                           //
//                           //
//                           //
///////////////////////////////


contract MB is ERC1155Creator {
    constructor() ERC1155Creator("Memeberrys", "MB") {}
}