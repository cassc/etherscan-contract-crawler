// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anthony Sal Abstract 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ███████╗ █████╗ ██╗         //
//    ██╔════╝██╔══██╗██║         //
//    ███████╗███████║██║         //
//    ╚════██║██╔══██║██║         //
//    ███████║██║  ██║███████╗    //
//    ╚══════╝╚═╝  ╚═╝╚══════╝    //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract SAL is ERC721Creator {
    constructor() ERC721Creator("Anthony Sal Abstract 1/1", "SAL") {}
}