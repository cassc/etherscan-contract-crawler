// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KURENAI SCREWDOWN COLLECTION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    KURENAI SCREWDOWN COLLECTION    //
//                                    //
//                                    //
////////////////////////////////////////


contract KSC is ERC721Creator {
    constructor() ERC721Creator("KURENAI SCREWDOWN COLLECTION", "KSC") {}
}