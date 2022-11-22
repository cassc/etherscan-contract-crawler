// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mid-Day x Surrealism
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ███╗   ███╗██████╗ ███████╗    //
//    ████╗ ████║██╔══██╗██╔════╝    //
//    ██╔████╔██║██║  ██║███████╗    //
//    ██║╚██╔╝██║██║  ██║╚════██║    //
//    ██║ ╚═╝ ██║██████╔╝███████║    //
//    ╚═╝     ╚═╝╚═════╝ ╚══════╝    //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract MDS is ERC721Creator {
    constructor() ERC721Creator("Mid-Day x Surrealism", "MDS") {}
}