// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Facing Ego
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ███████╗ █████╗ ███╗   ██╗    //
//    ██╔════╝██╔══██╗████╗  ██║    //
//    ███████╗███████║██╔██╗ ██║    //
//    ╚════██║██╔══██║██║╚██╗██║    //
//    ███████║██║  ██║██║ ╚████║    //
//    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝    //
//                                  //
//                                  //
//////////////////////////////////////


contract FE is ERC721Creator {
    constructor() ERC721Creator("Facing Ego", "FE") {}
}