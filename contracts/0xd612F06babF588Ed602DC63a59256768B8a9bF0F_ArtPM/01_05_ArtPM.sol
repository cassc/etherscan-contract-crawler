// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sweet Moment of Spring
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    ArtPM     //
//              //
//              //
//////////////////


contract ArtPM is ERC721Creator {
    constructor() ERC721Creator("Sweet Moment of Spring", "ArtPM") {}
}