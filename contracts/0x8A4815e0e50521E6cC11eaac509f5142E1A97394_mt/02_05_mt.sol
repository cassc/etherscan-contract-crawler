// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: manifold_test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ███╗   ███╗████████╗    //
//    ████╗ ████║╚══██╔══╝    //
//    ██╔████╔██║   ██║       //
//    ██║╚██╔╝██║   ██║       //
//    ██║ ╚═╝ ██║   ██║       //
//    ╚═╝     ╚═╝   ╚═╝       //
//                            //
//                            //
////////////////////////////////


contract mt is ERC721Creator {
    constructor() ERC721Creator("manifold_test", "mt") {}
}