// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HashesDAOTesting
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    MEOW    //
//            //
//            //
////////////////


contract HDT is ERC721Creator {
    constructor() ERC721Creator("HashesDAOTesting", "HDT") {}
}