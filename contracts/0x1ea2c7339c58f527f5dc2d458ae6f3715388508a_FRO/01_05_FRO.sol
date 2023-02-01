// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FROGGY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    (.)(.)    //
//              //
//              //
//////////////////


contract FRO is ERC721Creator {
    constructor() ERC721Creator("FROGGY", "FRO") {}
}