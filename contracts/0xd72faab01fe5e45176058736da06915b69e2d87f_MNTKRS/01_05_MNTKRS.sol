// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moon Tinkers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    MOONTINKERS    //
//                   //
//                   //
///////////////////////


contract MNTKRS is ERC721Creator {
    constructor() ERC721Creator("Moon Tinkers", "MNTKRS") {}
}