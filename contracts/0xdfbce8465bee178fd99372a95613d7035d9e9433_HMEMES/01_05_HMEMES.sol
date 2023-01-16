// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hirshmemes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Hirshon Memes    //
//                     //
//                     //
/////////////////////////


contract HMEMES is ERC721Creator {
    constructor() ERC721Creator("Hirshmemes", "HMEMES") {}
}