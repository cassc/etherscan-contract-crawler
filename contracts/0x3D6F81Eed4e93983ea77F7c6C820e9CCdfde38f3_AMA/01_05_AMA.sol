// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EyEm Artworks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    May Love Save Us All    //
//                            //
//    #longtermmemory         //
//                            //
//                            //
////////////////////////////////


contract AMA is ERC721Creator {
    constructor() ERC721Creator("EyEm Artworks", "AMA") {}
}