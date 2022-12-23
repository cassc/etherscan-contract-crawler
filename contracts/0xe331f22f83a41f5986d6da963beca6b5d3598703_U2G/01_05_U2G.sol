// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ultra_Urban
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    █╗   ██╗██████╗  ██████╗      //
//    ██║   ██║╚════██╗██╔════╝     //
//    ██║   ██║ █████╔╝██║  ███╗    //
//    ██║   ██║██╔═══╝ ██║   ██║    //
//    ╚██████╔╝███████╗╚██████╔╝    //
//     ╚═════╝ ╚══════╝ ╚═════╝     //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract U2G is ERC721Creator {
    constructor() ERC721Creator("Ultra_Urban", "U2G") {}
}