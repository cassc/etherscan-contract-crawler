// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: metaScreenPlays.Collabs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    metaScreenPlays.Collabs    //
//                               //
//                               //
///////////////////////////////////


contract MSPC is ERC721Creator {
    constructor() ERC721Creator("metaScreenPlays.Collabs", "MSPC") {}
}