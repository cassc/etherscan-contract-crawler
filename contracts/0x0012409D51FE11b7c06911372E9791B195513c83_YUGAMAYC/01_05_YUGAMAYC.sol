// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Ape Yacht Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    MAYC    //
//            //
//            //
////////////////


contract YUGAMAYC is ERC721Creator {
    constructor() ERC721Creator("Mutant Ape Yacht Club", "YUGAMAYC") {}
}