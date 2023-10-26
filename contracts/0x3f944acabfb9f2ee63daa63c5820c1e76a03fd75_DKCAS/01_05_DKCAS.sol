// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digital Kaleidoscope:Colors and Shapes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    NERLI    //
//             //
//             //
/////////////////


contract DKCAS is ERC721Creator {
    constructor() ERC721Creator("Digital Kaleidoscope:Colors and Shapes", "DKCAS") {}
}