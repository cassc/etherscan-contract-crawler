// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: njr01
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//    ███╗   ██╗     ██╗██████╗     //
//    ████╗  ██║     ██║██╔══██╗    //
//    ██╔██╗ ██║     ██║██████╔╝    //
//    ██║╚██╗██║██   ██║██╔══██╗    //
//    ██║ ╚████║╚█████╔╝██║  ██║    //
//    ╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝    //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract njr01 is ERC1155Creator {
    constructor() ERC1155Creator("njr01", "njr01") {}
}