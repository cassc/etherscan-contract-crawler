// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BANI's IROIRO Fanart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ♥♡♥♡♥♡♥♡♥    //
//                 //
//                 //
/////////////////////


contract IROIROBANI is ERC721Creator {
    constructor() ERC721Creator("BANI's IROIRO Fanart", "IROIROBANI") {}
}