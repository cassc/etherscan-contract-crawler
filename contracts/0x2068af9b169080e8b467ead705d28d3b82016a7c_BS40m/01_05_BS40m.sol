// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BASE40M_MF
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ASCII art iz wack    //
//                         //
//                         //
/////////////////////////////


contract BS40m is ERC721Creator {
    constructor() ERC721Creator("BASE40M_MF", "BS40m") {}
}