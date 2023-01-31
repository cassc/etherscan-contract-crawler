// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AYU Stamps
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     █████╗ ██╗   ██╗██╗   ██╗    //
//    ██╔══██╗╚██╗ ██╔╝██║   ██║    //
//    ███████║ ╚████╔╝ ██║   ██║    //
//    ██╔══██║  ╚██╔╝  ██║   ██║    //
//    ██║  ██║   ██║   ╚██████╔╝    //
//    ╚═╝  ╚═╝   ╚═╝    ╚═════╝     //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract STAMP is ERC721Creator {
    constructor() ERC721Creator("AYU Stamps", "STAMP") {}
}