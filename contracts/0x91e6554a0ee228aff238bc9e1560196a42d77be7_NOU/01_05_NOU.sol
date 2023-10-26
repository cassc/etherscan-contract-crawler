// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTO NOU
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ███╗   ██╗ ██████╗ ██╗   ██╗    //
//    ████╗  ██║██╔═══██╗██║   ██║    //
//    ██╔██╗ ██║██║   ██║██║   ██║    //
//    ██║╚██╗██║██║   ██║██║   ██║    //
//    ██║ ╚████║╚██████╔╝╚██████╔╝    //
//    ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝     //
//                                    //
//                                    //
////////////////////////////////////////


contract NOU is ERC721Creator {
    constructor() ERC721Creator("CRYPTO NOU", "NOU") {}
}