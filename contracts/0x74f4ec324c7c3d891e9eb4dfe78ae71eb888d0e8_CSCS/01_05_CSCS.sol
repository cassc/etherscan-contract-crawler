// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colors Connections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    CSCS    //
//            //
//            //
////////////////


contract CSCS is ERC721Creator {
    constructor() ERC721Creator("Colors Connections", "CSCS") {}
}