// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtbyJArthurDrawings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ArtbyJArthurDrawings    //
//                            //
//                            //
////////////////////////////////


contract AJAD is ERC721Creator {
    constructor() ERC721Creator("ArtbyJArthurDrawings", "AJAD") {}
}