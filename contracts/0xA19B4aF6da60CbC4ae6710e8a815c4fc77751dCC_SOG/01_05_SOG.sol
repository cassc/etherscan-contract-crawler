// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spaced Out Graffiti
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Spaced Out Graffiti    //
//                           //
//                           //
///////////////////////////////


contract SOG is ERC721Creator {
    constructor() ERC721Creator("Spaced Out Graffiti", "SOG") {}
}