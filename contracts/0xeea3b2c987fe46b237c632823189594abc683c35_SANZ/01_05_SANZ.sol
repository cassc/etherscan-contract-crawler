// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sanuri Zulkefli Arts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
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


contract SANZ is ERC721Creator {
    constructor() ERC721Creator("Sanuri Zulkefli Arts", "SANZ") {}
}