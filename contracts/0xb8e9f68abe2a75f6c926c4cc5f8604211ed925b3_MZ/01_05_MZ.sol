// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MARCO ZAGARA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ███╗   ███╗███████╗    //
//    ████╗ ████║╚══███╔╝    //
//    ██╔████╔██║  ███╔╝     //
//    ██║╚██╔╝██║ ███╔╝      //
//    ██║ ╚═╝ ██║███████╗    //
//    ╚═╝     ╚═╝╚══════╝    //
//                           //
//                           //
///////////////////////////////


contract MZ is ERC721Creator {
    constructor() ERC721Creator("MARCO ZAGARA", "MZ") {}
}