// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRUTH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     █████╗  ██████╗██╗  ██╗    //
//    ██╔══██╗██╔════╝╚██╗██╔╝    //
//    ███████║██║      ╚███╔╝     //
//    ██╔══██║██║      ██╔██╗     //
//    ██║  ██║╚██████╗██╔╝ ██╗    //
//    ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    //
//                                //
//                                //
//                                //
////////////////////////////////////


contract ACXs is ERC721Creator {
    constructor() ERC721Creator("TRUTH", "ACXs") {}
}