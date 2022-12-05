// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bryan Freudeman Art Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    BryanFreudemanArt.eth    //
//                             //
//                             //
/////////////////////////////////


contract BAF is ERC721Creator {
    constructor() ERC721Creator("Bryan Freudeman Art Editions", "BAF") {}
}