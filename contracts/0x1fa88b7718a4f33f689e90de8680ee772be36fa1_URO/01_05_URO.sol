// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: URO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    1627    //
//            //
//            //
////////////////


contract URO is ERC721Creator {
    constructor() ERC721Creator("URO", "URO") {}
}