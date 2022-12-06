// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sky
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    Somewhere over the rainbow, skies are blue.    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract bluesky is ERC721Creator {
    constructor() ERC721Creator("Sky", "bluesky") {}
}