// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTICDOGGIESV2.0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    COLLECTION: CRYPTICDOGGIESV2.0    //
//    ARTIST: CRYPTIC SAMSARA           //
//    STUDIO: CRYPTIC STUDIOS           //
//                                      //
//                                      //
//////////////////////////////////////////


contract CDG is ERC721Creator {
    constructor() ERC721Creator("CRYPTICDOGGIESV2.0", "CDG") {}
}