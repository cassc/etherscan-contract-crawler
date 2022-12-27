// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sisipatake
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ███████╗██╗███████╗██╗    //
//    ██╔════╝██║██╔════╝██║    //
//    ███████╗██║███████╗██║    //
//    ╚════██║██║╚════██║██║    //
//    ███████║██║███████║██║    //
//    ╚══════╝╚═╝╚══════╝╚═╝    //
//                              //
//                              //
//////////////////////////////////


contract sisi is ERC721Creator {
    constructor() ERC721Creator("sisipatake", "sisi") {}
}